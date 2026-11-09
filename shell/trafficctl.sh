#!/bin/bash
# ==============================================================================
# TrafficCtl 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从 YusDyr/luci-app-trafficctl 官方 Releases latest 获取 OpenWrt 25.12 SDK 构建的 APK：
#    - 主包：luci-app-trafficctl_<ver>-r1_noarch.apk (回退 luci-app-trafficctl.apk)
#    - 中文语言包：luci-i18n-trafficctl-zh-cn_<ver>-r1_noarch.apk
# 2. 注入 /home/build/immortalwrt/packages/
# 3. 更新 /home/build/immortalwrt/packages/packages.adb 索引数据库供 ImageBuilder 构建使用
# ==============================================================================

set -e

echo "=== 正在执行 TrafficCtl 模块准备工作 (25.12 APK) ==="

REPO="YusDyr/luci-app-trafficctl"
PKG_DIR="/home/build/immortalwrt/packages"
TMP_DIR="/tmp/trafficctl-download"

mkdir -p "$PKG_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

MAIN_APK_URL=""
I18N_APK_URL=""

# 1. 优先通过 GitHub Releases latest API 检索 .apk 下载直链
API_RES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 || true)
    MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-trafficctl_[0-9][^/]*\.apk$' | head -n1 || true)
    if [ -z "$MAIN_APK_URL" ]; then
        MAIN_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-app-trafficctl\.apk$' | head -n1 || true)
    fi
    I18N_APK_URL=$(printf '%s\n' "$URLS" | grep -E '/luci-i18n-trafficctl-zh-cn[-_][^/]*\.apk$' | head -n1 || true)
fi

# 2. 若 GitHub API 触发限流或未完整返回，通过 Releases 重定向与 expanded_assets 页面抓取
if [ -z "$MAIN_APK_URL" ] || [ -z "$I18N_APK_URL" ]; then
    echo "GitHub API 未完整返回资产链接，正在尝试从 Releases 页面解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        ASSETS_HTML=$(curl -fsSL "https://github.com/${REPO}/releases/expanded_assets/${LATEST_TAG}" 2>/dev/null || true)
        if [ -n "$ASSETS_HTML" ]; then
            if [ -z "$MAIN_APK_URL" ]; then
                MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^\"]+/luci-app-trafficctl_[0-9][^\"]*\.apk" | head -n1 || true)
                if [ -z "$MAIN_PATH" ]; then
                    MAIN_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^\"]+/luci-app-trafficctl\.apk" | head -n1 || true)
                fi
                if [ -n "$MAIN_PATH" ]; then
                    MAIN_APK_URL="https://github.com${MAIN_PATH}"
                fi
            fi
            if [ -z "$I18N_APK_URL" ]; then
                I18N_PATH=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^\"]+/luci-i18n-trafficctl-zh-cn[-_][^\"]*\.apk" | head -n1 || true)
                if [ -n "$I18N_PATH" ]; then
                    I18N_APK_URL="https://github.com${I18N_PATH}"
                fi
            fi
        fi

        LATEST_VER="${LATEST_TAG#v}"
        if [ -z "$MAIN_APK_URL" ]; then
            MAIN_APK_URL="https://github.com/${REPO}/releases/latest/download/luci-app-trafficctl.apk"
        fi
        if [ -z "$I18N_APK_URL" ] && [ -n "$LATEST_VER" ]; then
            I18N_APK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/luci-i18n-trafficctl-zh-cn_${LATEST_VER}-r1_noarch.apk"
        fi
    fi
fi

if [ -z "$MAIN_APK_URL" ]; then
    echo "错误：无法获取 luci-app-trafficctl 25.12 APK 下载地址"
    exit 1
fi

if [ -z "$I18N_APK_URL" ]; then
    echo "错误：无法获取 luci-i18n-trafficctl-zh-cn 25.12 APK 下载地址"
    exit 1
fi

MAIN_APK_FILE="${TMP_DIR}/$(basename "$MAIN_APK_URL")"
I18N_APK_FILE="${TMP_DIR}/$(basename "$I18N_APK_URL")"

echo "正在下载 luci-app-trafficctl APK: $MAIN_APK_URL"
curl -fsSL "$MAIN_APK_URL" -o "$MAIN_APK_FILE"

echo "正在下载 luci-i18n-trafficctl-zh-cn APK: $I18N_APK_URL"
curl -fsSL "$I18N_APK_URL" -o "$I18N_APK_FILE"

if [ ! -s "$MAIN_APK_FILE" ] || [ ! -s "$I18N_APK_FILE" ]; then
    echo "错误：下载的 TrafficCtl APK 文件为空"
    exit 1
fi

# 清理旧版本同名包并复制到 packages 目录
rm -f "${PKG_DIR}"/luci-app-trafficctl*.apk "${PKG_DIR}"/luci-i18n-trafficctl*.apk
cp -v "$MAIN_APK_FILE" "$I18N_APK_FILE" "$PKG_DIR/"
rm -rf "$TMP_DIR"

# 3. 为 packages 目录生成/更新 APK 索引数据库 (packages.adb)
if command -v apk >/dev/null 2>&1; then
    echo "正在为 packages 目录生成/更新 APK 索引数据库 (packages.adb)..."
    (cd "$PKG_DIR" && apk mkndx --allow-untrusted -o packages.adb *.apk)
    echo "APK 索引数据库更新完成"
fi

echo "当前 packages 目录内容清单:"
ls -lah "$PKG_DIR/"

echo "=== TrafficCtl 模块准备完成 ==="
