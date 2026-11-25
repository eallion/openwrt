#!/bin/bash
# ==============================================================================
# TrafficCtl 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从 YusDyr/luci-app-trafficctl 官方 Releases latest 动态获取 OpenWrt 25.12 SDK 构建的全部 APK：
#    - 完整功能包：trafficctl-full_<ver>-r1_noarch.apk (v2.3.0+ 起 luci-app-trafficctl 依赖此包)
#    - 基础核心包：trafficctl_<ver>-r1_noarch.apk
#    - 扩展功能包：trafficctl-telegram、trafficctl-shaper、trafficctl-wifi 等
#    - Web 界面主包：luci-app-trafficctl_<ver>-r1_noarch.apk
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

URLS=""

# 1. 优先通过 GitHub Releases latest API 检索全部 .apk 下载直链
API_RES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    # 优先筛选带有版本号规范命名的 APK（如 *_2.3.0-r1_noarch.apk），防止重复下载无版本别名文件
    URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 | grep -E '/[^/]+_[0-9][^/]*\.apk$' | sort -u || true)
    # 若未找到带版本号命名的包，回退匹配全部非重复 .apk
    if [ -z "$URLS" ]; then
        URLS=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 | grep -E '\.apk$' | grep -v '_noarch\.apk$' | sort -u || true)
    fi
fi

# 2. 若 GitHub API 触发限流或未完整返回，通过 Releases 重定向与 expanded_assets 页面抓取
if [ -z "$URLS" ]; then
    echo "GitHub API 未返回资产链接，正在尝试从 Releases 页面解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        ASSETS_HTML=$(curl -fsSL "https://github.com/${REPO}/releases/expanded_assets/${LATEST_TAG}" 2>/dev/null || true)
        if [ -n "$ASSETS_HTML" ]; then
            PATHS=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/[^/\"]+_[0-9][^/\"]*\.apk" | sort -u || true)
            if [ -z "$PATHS" ]; then
                PATHS=$(printf '%s\n' "$ASSETS_HTML" | grep -oE "/${REPO}/releases/download/[^/\"]+/[^/\"]+\.apk" | grep -v '_noarch\.apk' | sort -u || true)
            fi
            for p in $PATHS; do
                URLS="${URLS} https://github.com${p}"
            done
        fi
    fi
fi

if [ -z "$URLS" ]; then
    echo "错误：无法获取 TrafficCtl 相关 APK 下载地址"
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

# 3. 下载全部 APK 并按规范注入 packages 目录
# 清理 packages 目录中的旧版本同名包
rm -f "${PKG_DIR}"/trafficctl*.apk "${PKG_DIR}"/luci-app-trafficctl*.apk "${PKG_DIR}"/luci-i18n-trafficctl*.apk

DOWNLOADED_COUNT=0
for url in $URLS; do
    [ -z "$url" ] && continue
    apk_name=$(basename "$url")
    dest="${TMP_DIR}/${apk_name}"
    echo "正在下载 TrafficCtl APK: $url"
    curl -fsSL "$url" -o "$dest"
    if [ ! -s "$dest" ]; then
        echo "错误：下载的 APK 文件为空: $apk_name"
        exit 1
    fi

    canonical_name=$(get_canonical_apk_name "$dest")
    if [ -z "$canonical_name" ]; then
        echo "错误：无法从 $apk_name 解析包名或版本号"
        exit 1
    fi
    cp -v "$dest" "${PKG_DIR}/${canonical_name}"
    DOWNLOADED_COUNT=$((DOWNLOADED_COUNT + 1))
done

rm -rf "$TMP_DIR"

if [ "$DOWNLOADED_COUNT" -eq 0 ]; then
    echo "错误：未能成功下载任何 TrafficCtl APK"
    exit 1
fi

# 4. 索引处理：若本地签名私钥已存在则更新已签名 packages.adb；否则清理旧索引，
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
