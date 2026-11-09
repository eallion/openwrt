#!/bin/bash
# ==============================================================================
# TrafficCtl 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从 YusDyr/luci-app-trafficctl 官方 Releases latest 获取 OpenWrt 25.12 SDK 构建的 APK：
#    - 后端核心包：trafficctl_<ver>-r1_noarch.apk (回退 trafficctl.apk，v1.29.0+ 起拆出)
#    - Web 界面主包：luci-app-trafficctl_<ver>-r1_noarch.apk (回退 luci-app-trafficctl.apk)
#    - 中文语言包：luci-i18n-trafficctl-zh-cn_<ver>-r1_noarch.apk
# 2. 通过 apk adbdump 读取包内真实 name 与 version，按 <name>-<version>.apk 规范
#    重命名后注入 /home/build/immortalwrt/packages/（解决上游发布文件名与包元数据
#    不一致导致的 package mentioned in index not found 问题）
# 3. 仅当本地签名私钥存在时生成已签名 packages.adb，否则清理旧索引交由 ImageBuilder 签发
# ==============================================================================

set -e

echo "=== 正在执行 TrafficCtl 模块准备工作 (25.12 APK) ==="

REPO="YusDyr/luci-app-trafficctl"
PKG_DIR="/home/build/immortalwrt/packages"
TMP_DIR="/tmp/trafficctl-download"

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

CORE_APK_URL=""
MAIN_APK_URL=""
I18N_APK_URL=""

# 1. 优先通过 GitHub Releases latest API 检索 .apk 下载直链
API_RES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 || true)
    CORE_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/trafficctl[-_][0-9][^/]*\.apk$' | head -n1 || true)
    if [ -z "$CORE_APK_URL" ]; then
        CORE_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/trafficctl\.apk$' | head -n1 || true)
    fi
    MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-trafficctl[-_][0-9][^/]*\.apk$' | head -n1 || true)
    if [ -z "$MAIN_APK_URL" ]; then
        MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-trafficctl\.apk$' | head -n1 || true)
    fi
    I18N_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-i18n-trafficctl-zh-cn[-_][^/]*\.apk$' | head -n1 || true)
fi

# 2. 若 GitHub API 触发限流或未完整返回，通过 Releases 重定向与 expanded_assets 页面抓取
if [ -z "$CORE_APK_URL" ] || [ -z "$MAIN_APK_URL" ] || [ -z "$I18N_APK_URL" ]; then
    echo "GitHub API 未完整返回资产链接，正在尝试从 Releases 页面解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        ASSETS_HTML=$(curl -fsSL "https://github.com/${REPO}/releases/expanded_assets/${LATEST_TAG}" 2>/dev/null || true)
        if [ -n "$ASSETS_HTML" ]; then
            if [ -z "$CORE_APK_URL" ]; then
                CORE_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/trafficctl[-_][0-9][^/\"]*\.apk" | head -n1 || true)
                if [ -z "$CORE_PATH" ]; then
                    CORE_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/trafficctl\.apk" | head -n1 || true)
                fi
                if [ -n "$CORE_PATH" ]; then
                    CORE_APK_URL="https://github.com${CORE_PATH}"
                fi
            fi
            if [ -z "$MAIN_APK_URL" ]; then
                MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-app-trafficctl[-_][0-9][^/\"]*\.apk" | head -n1 || true)
                if [ -z "$MAIN_PATH" ]; then
                    MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-app-trafficctl\.apk" | head -n1 || true)
                fi
                if [ -n "$MAIN_PATH" ]; then
                    MAIN_APK_URL="https://github.com${MAIN_PATH}"
                fi
            fi
            if [ -z "$I18N_APK_URL" ]; then
                I18N_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/luci-i18n-trafficctl-zh-cn[-_][^/\"]*\.apk" | head -n1 || true)
                if [ -n "$I18N_PATH" ]; then
                    I18N_APK_URL="https://github.com${I18N_PATH}"
                fi
            fi
        fi

        LATEST_VER="${LATEST_TAG#v}"
        if [ -z "$CORE_APK_URL" ]; then
            CORE_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/trafficctl.apk"
        fi
        if [ -z "$MAIN_APK_URL" ]; then
            MAIN_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-app-trafficctl.apk"
        fi
        if [ -z "$I18N_APK_URL" ] && [ -n "$LATEST_VER" ]; then
            I18N_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-i18n-trafficctl-zh-cn_${LATEST_VER}-r1_noarch.apk"
        fi
    fi
fi

if [ -z "$CORE_APK_URL" ]; then
    echo "错误：无法获取 trafficctl 核心 25.12 APK 下载地址"
    exit 1
fi

if [ -z "$MAIN_APK_URL" ]; then
    echo "错误：无法获取 luci-app-trafficctl 25.12 APK 下载地址"
    exit 1
fi

if [ -z "$I18N_APK_URL" ]; then
    echo "错误：无法获取 luci-i18n-trafficctl-zh-cn 25.12 APK 下载地址"
    exit 1
fi

CORE_APK_FILE="${TMP_DIR}/$(basename "$CORE_APK_URL")"
MAIN_APK_FILE="${TMP_DIR}/$(basename "$MAIN_APK_URL")"
I18N_APK_FILE="${TMP_DIR}/$(basename "$I18N_APK_URL")"

echo "正在下载 trafficctl APK: $CORE_APK_URL"
curl -fsSL "$CORE_APK_URL" -o "$CORE_APK_FILE"

echo "正在下载 luci-app-trafficctl APK: $MAIN_APK_URL"
curl -fsSL "$MAIN_APK_URL" -o "$MAIN_APK_FILE"

echo "正在下载 luci-i18n-trafficctl-zh-cn APK: $I18N_APK_URL"
curl -fsSL "$I18N_APK_URL" -o "$I18N_APK_FILE"

if [ ! -s "$CORE_APK_FILE" ] || [ ! -s "$MAIN_APK_FILE" ] || [ ! -s "$I18N_APK_FILE" ]; then
    echo "错误：下载的 TrafficCtl APK 文件为空"
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

CORE_CANONICAL_NAME=$(get_canonical_apk_name "$CORE_APK_FILE")
MAIN_CANONICAL_NAME=$(get_canonical_apk_name "$MAIN_APK_FILE")
I18N_CANONICAL_NAME=$(get_canonical_apk_name "$I18N_APK_FILE")

if [ -z "$CORE_CANONICAL_NAME" ] || [ -z "$MAIN_CANONICAL_NAME" ] || [ -z "$I18N_CANONICAL_NAME" ]; then
    echo "错误：无法从下载的 TrafficCtl APK 中解析包名或版本号"
    exit 1
fi

# 清理旧版本同名包并按 <name>-<version>.apk 规范复制到 packages 目录
rm -f "${PKG_DIR}"/trafficctl-*.apk "${PKG_DIR}"/trafficctl_*.apk "${PKG_DIR}"/trafficctl.apk "${PKG_DIR}"/luci-app-trafficctl*.apk "${PKG_DIR}"/luci-i18n-trafficctl*.apk
cp -v "$CORE_APK_FILE" "${PKG_DIR}/${CORE_CANONICAL_NAME}"
cp -v "$MAIN_APK_FILE" "${PKG_DIR}/${MAIN_CANONICAL_NAME}"
cp -v "$I18N_APK_FILE" "${PKG_DIR}/${I18N_CANONICAL_NAME}"
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

echo "=== TrafficCtl 模块准备完成 ==="
