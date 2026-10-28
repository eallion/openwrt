#!/bin/bash
# ==============================================================================
# EasyTier 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 获取 EasyTier 官方发布的最新的 x86_64 SNAPSHOT (APK) 安装包合辑
#    (EasyTier-v*-x86_64-SNAPSHOT.zip)
# 2. 解压并提取核心包 (easytier)、Web 界面 (luci-app-easytier) 及中文包 (luci-i18n-easytier-zh-cn)
#    自动剔除冲突的 noweb 包，并注入 /home/build/immortalwrt/packages/
# 3. 自动生成/刷新 packages/packages.adb 索引数据库供 ImageBuilder 构建使用
# ==============================================================================

set -e

echo "=== 正在执行 EasyTier 模块准备工作 (25.12 APK) ==="

mkdir -p /home/build/immortalwrt/packages

# 1. 获取 EasyTier 官方发布页中 x86_64 SNAPSHOT 压缩包直链 (支持 API 与页面直接解析双通道)
get_release_zip_url() {
    local url=""

    # 尝试通过 GitHub Releases API 检索
    local api_res
    api_res=$(curl -sL https://api.github.com/repos/EasyTier/luci-app-easytier/releases 2>/dev/null || true)
    if [ -n "$api_res" ]; then
        url=$(echo "$api_res" | grep "browser_download_url" | grep -i "x86_64" | grep -i "SNAPSHOT" | grep -i "\.zip\"" | head -n1 | cut -d '"' -f 4)
    fi

    # 若 API 触发限流或未获取到，直接解析 Releases 网页 HTML
    if [ -z "$url" ]; then
        echo "GitHub API 检索未返回结果，正在尝试直接从 Releases 网页抓取..."
        local page_html
        page_html=$(curl -sL https://github.com/EasyTier/luci-app-easytier/releases 2>/dev/null || true)
        if [ -n "$page_html" ]; then
            url=$(echo "$page_html" | grep -oiE '/EasyTier/luci-app-easytier/releases/download/[^"]+x86_64[^"]*SNAPSHOT[^"]*\.zip' | head -n1)
            [ -n "$url" ] && url="https://github.com${url}"
        fi
    fi

    echo "$url"
}

EASYTIER_ZIP_URL=$(get_release_zip_url)

if [ -z "$EASYTIER_ZIP_URL" ]; then
    echo "错误：无法获取 EasyTier x86_64 SNAPSHOT 下载地址"
    exit 1
fi

echo "正在下载 EasyTier 25.12 APK 安装包合辑: $EASYTIER_ZIP_URL"
wget -q "$EASYTIER_ZIP_URL" -O /tmp/easytier.zip

mkdir -p /tmp/easytier-unpack
if command -v unzip >/dev/null 2>&1; then
    unzip -o -q /tmp/easytier.zip -d /tmp/easytier-unpack
else
    python3 -m zipfile -e /tmp/easytier.zip /tmp/easytier-unpack
fi

# 排除 easytier-noweb 安装包，避免与完整版 easytier 产生 provider 冲突
find /tmp/easytier-unpack -type f -name "*noweb*" -delete

# 复制解压出的 apk 软件包到 packages 目录
find /tmp/easytier-unpack -type f -name "*.apk" -exec cp -v {} /home/build/immortalwrt/packages/ \;
rm -rf /tmp/easytier-unpack /tmp/easytier.zip

# 2. 为 packages 目录生成/更新 APK 索引数据库 (packages.adb)
if command -v apk >/dev/null 2>&1; then
    echo "正在为 packages 目录生成/更新 APK 索引数据库 (packages.adb)..."
    (cd /home/build/immortalwrt/packages && apk mkndx --allow-untrusted -o packages.adb *.apk 2>/dev/null || true)
    echo "APK 索引数据库更新完成"
fi

echo "当前 packages 目录内容清单:"
ls -lah /home/build/immortalwrt/packages/

echo "=== EasyTier 模块准备完成 ==="
