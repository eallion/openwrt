#!/bin/bash
# ==============================================================================
# Nginx Manager 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从 hello-yunshu/luci-app-nginx-manager 官方 Releases latest 获取
#    luci-app-nginx-manager-<ver>-r<rel>.apk（内置中文语言包，无独立 i18n 拆包）
# 2. 通过 apk adbdump 读取包内真实 name 与 version，按 <name>-<version>.apk 规范
#    重命名后注入 /home/build/immortalwrt/packages/
# 3. 仅当本地签名私钥存在时生成已签名 packages.adb，否则清理旧索引交由 ImageBuilder 签发
# 4. 运行依赖由 ImageBuilder 从官方源自动解析（继续沿用 luci-nginx 默认的 nginx-ssl，不启用 QUIC）
# ==============================================================================

set -e

echo "=== 正在执行 Nginx Manager 模块准备工作 (25.12 APK) ==="

REPO="hello-yunshu/luci-app-nginx-manager"
PKG_DIR="/home/build/immortalwrt/packages"
TMP_DIR="/tmp/nginx-manager-download"

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

MAIN_APK_URL=""

# 1. 优先通过 GitHub Releases latest API 检索 .apk 下载直链
API_RES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 || true)
    MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-nginx-manager[-_][0-9][^/]*\.apk$' | head -n1 || true)
    if [ -z "$MAIN_APK_URL" ]; then
        MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-nginx-manager\.apk$' | head -n1 || true)
    fi
fi

# 2. 若 GitHub API 触发限流或未返回，通过 Releases 重定向与 expanded_assets 页面抓取
if [ -z "$MAIN_APK_URL" ]; then
    echo "GitHub API 未返回资产链接，正在尝试从 Releases 页面解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        ASSETS_HTML=$(curl -fsSL "https://github.com/${REPO}/releases/expanded_assets/${LATEST_TAG}" 2>/dev/null || true)
        if [ -n "$ASSETS_HTML" ]; then
            MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-app-nginx-manager[-_][0-9][^/\"]*\.apk" | head -n1 || true)
            if [ -z "$MAIN_PATH" ]; then
                MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-app-nginx-manager\.apk" | head -n1 || true)
            fi
            if [ -n "$MAIN_PATH" ]; then
                MAIN_APK_URL="https://github.com${MAIN_PATH}"
            fi
        fi

        if [ -z "$MAIN_APK_URL" ]; then
            TAG_NO_V="${LATEST_TAG#v}"
            case "$TAG_NO_V" in
                *-*)
                    VER_PART="${TAG_NO_V%-*}"
                    REL_PART="${TAG_NO_V##*-}"
                    MAIN_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-app-nginx-manager-${VER_PART}-r${REL_PART}.apk"
                    ;;
                *)
                    MAIN_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-app-nginx-manager-${TAG_NO_V}-r1.apk"
                    ;;
            esac
        fi
    fi
fi

if [ -z "$MAIN_APK_URL" ]; then
    echo "错误：无法获取 luci-app-nginx-manager 25.12 APK 下载地址"
    exit 1
fi

MAIN_APK_FILE="${TMP_DIR}/$(basename "$MAIN_APK_URL")"

echo "正在下载 luci-app-nginx-manager APK: $MAIN_APK_URL"
curl -fsSL "$MAIN_APK_URL" -o "$MAIN_APK_FILE"

if [ ! -s "$MAIN_APK_FILE" ]; then
    echo "错误：下载的 luci-app-nginx-manager APK 文件为空"
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

MAIN_CANONICAL_NAME=$(get_canonical_apk_name "$MAIN_APK_FILE")

if [ -z "$MAIN_CANONICAL_NAME" ]; then
    echo "错误：无法从下载的 luci-app-nginx-manager APK 中解析包名或版本号"
    exit 1
fi

# 清理旧版本同名包并按 <name>-<version>.apk 规范复制到 packages 目录
rm -f "${PKG_DIR}"/luci-app-nginx-manager*.apk
cp -v "$MAIN_APK_FILE" "${PKG_DIR}/${MAIN_CANONICAL_NAME}"
rm -rf "$TMP_DIR"

# 3. 索引处理：若本地签名私钥已存在则更新已签名 packages.adb；否则清理旧索引，
#    交由 ImageBuilder 在 make image (package_index) 阶段生成并签名，防止未签名索引跳过签名校验
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

echo "=== Nginx Manager 模块准备完成 ==="
