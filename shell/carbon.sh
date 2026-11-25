#!/bin/bash
# ==============================================================================
# Carbon 主题独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从 mrjoechen/luci-theme-carbon 官方 Releases latest 获取：
#    - 主题包：luci-theme-carbon-*.apk (或 luci-theme-carbon_*.apk)
#    - 验签公钥：carbon-apk.pem (注入 /etc/apk/keys 供系统与在线升级验签)
# 2. 通过 apk adbdump 读取包内真实 name 与 version，按 <name>-<version>.apk 规范
#    重命名后注入 /home/build/immortalwrt/packages/（解决上游发布文件名与包元数据
#    不一致导致的 package mentioned in index not found 问题）
# 3. 仅当本地签名私钥存在时生成已签名 packages.adb，否则清理旧索引交由 ImageBuilder 签发
# ==============================================================================

set -e

echo "=== 正在执行 Carbon 主题模块准备工作 (25.12 APK) ==="

REPO="mrjoechen/luci-theme-carbon"
PKG_DIR="/home/build/immortalwrt/packages"
TMP_DIR="/tmp/carbon-download"
FILES_DIR="files/etc/apk/keys"

# 定位 apk-tools v3 可执行文件
APK_BIN="$(command -v apk || true)"
if [ -z "$APK_BIN" ] && [ -x /home/build/immortalwrt/staging_dir/host/bin/apk ]; then
    APK_BIN="/home/build/immortalwrt/staging_dir/host/bin/apk"
elif [ -z "$APK_BIN" ] && [ -x ./staging_dir/host/bin/apk ]; then
    APK_BIN="./staging_dir/host/bin/apk"
fi

if [ -z "$APK_BIN" ]; then
    echo "错误：未找到 apk 工具（请在 OpenWrt 25.12 ImageBuilder 容器环境中运行）"
    exit 1
fi

mkdir -p "$PKG_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

THEME_APK_URL=""
KEY_URL=""

# 1. 优先通过 GitHub Releases latest API 检索 .apk 与 .pem 下载直链
API_RES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 || true)
    THEME_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-theme-carbon[-_][0-9][^/]*\.apk$' | head -n1 || true)
    if [ -z "$THEME_APK_URL" ]; then
        THEME_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-theme-carbon\.apk$' | head -n1 || true)
    fi
    KEY_URL=$(printf '%s\n' "$URLS" | grep -E '/carbon-apk\.pem$' | head -n1 || true)
fi

# 2. 若 GitHub API 限流或未返回，通过 Releases 重定向与 expanded_assets 页面抓取
if [ -z "$THEME_APK_URL" ]; then
    echo "GitHub API 未完整返回资产链接，正在尝试从 Releases 页面解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        ASSETS_HTML=$(curl -fsSL "https://github.com/${REPO}/releases/expanded_assets/${LATEST_TAG}" 2>/dev/null || true)
        if [ -n "$ASSETS_HTML" ]; then
            THEME_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-theme-carbon[-_][0-9][^/\"]*\.apk" | head -n1 || true)
            if [ -z "$THEME_PATH" ]; then
                THEME_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-theme-carbon\.apk" | head -n1 || true)
            fi
            if [ -n "$THEME_PATH" ]; then
                THEME_APK_URL="https://github.com${THEME_PATH}"
            fi

            KEY_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/carbon-apk\.pem" | head -n1 || true)
            if [ -n "$KEY_PATH" ]; then
                KEY_URL="https://github.com${KEY_PATH}"
            fi
        fi

        if [ -z "$THEME_APK_URL" ]; then
            THEME_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-theme-carbon.apk"
        fi
        if [ -z "$KEY_URL" ]; then
            KEY_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/carbon-apk.pem"
        fi
    fi
fi

if [ -z "$THEME_APK_URL" ]; then
    echo "错误：无法获取 luci-theme-carbon APK 下载地址"
    exit 1
fi

THEME_APK_FILE="${TMP_DIR}/$(basename "$THEME_APK_URL")"
echo "正在下载 luci-theme-carbon APK: $THEME_APK_URL"
curl -fsSL "$THEME_APK_URL" -o "$THEME_APK_FILE"

if [ -n "$KEY_URL" ]; then
    KEY_FILE="${TMP_DIR}/carbon-apk.pem"
    echo "正在下载 Carbon 验签公钥: $KEY_URL"
    if curl -fsSL "$KEY_URL" -o "$KEY_FILE" 2>/dev/null && [ -s "$KEY_FILE" ]; then
        mkdir -p "$FILES_DIR"
        cp -v "$KEY_FILE" "${FILES_DIR}/carbon-apk.pem"
        if [ -d /home/build/immortalwrt/keys ]; then
            cp -v "$KEY_FILE" /home/build/immortalwrt/keys/carbon-apk.pem 2>/dev/null || true
        fi
    fi
fi

if [ ! -s "$THEME_APK_FILE" ]; then
    echo "错误：下载的 luci-theme-carbon APK 文件为空"
    exit 1
fi

get_canonical_apk_name() {
    local apk_file="$1"
    local adb_json
    adb_json=$("$APK_BIN" adbdump --format json "$apk_file") || return 1
    printf '%s' "$adb_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
info = data['info']
name = info['name'].strip()
version = info['version'].strip()
if not name or not version:
    raise ValueError('missing name or version')
print(f'{name}-{version}.apk')
"
}

THEME_CANONICAL_NAME=$(get_canonical_apk_name "$THEME_APK_FILE")
if [ -z "$THEME_CANONICAL_NAME" ]; then
    echo "错误：无法从下载的 luci-theme-carbon APK 中解析包名或版本号"
    exit 1
fi

# 清理旧版本同名包并按 <name>-<version>.apk 规范复制到 packages 目录
rm -f "${PKG_DIR}"/luci-theme-carbon*.apk
cp -v "$THEME_APK_FILE" "${PKG_DIR}/${THEME_CANONICAL_NAME}"
rm -rf "$TMP_DIR"

# 3. 索引处理：若本地签名私钥已存在则更新已签名 packages.adb；否则清理旧索引交由 ImageBuilder 签发
if [ -f /home/build/immortalwrt/keys/local-private-key.pem ]; then
    echo "正在为 packages 目录生成/更新已签名 APK 索引数据库 (packages.adb)..."
    (cd "$PKG_DIR" && "$APK_BIN" mkndx \
        --keys-dir /home/build/immortalwrt/keys \
        --sign /home/build/immortalwrt/keys/local-private-key.pem \
        --allow-untrusted \
        -o packages.adb *.apk)
    echo "APK 索引数据库更新完成"
else
    rm -f "${PKG_DIR}/packages.adb"
fi

echo "当前 packages 目录内容清单:"
ls -lah "$PKG_DIR/"

echo "=== Carbon 主题模块准备完成 ==="
