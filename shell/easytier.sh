#!/bin/bash
# ==============================================================================
# EasyTier 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 下载 EasyTier 官方发布的 x86_64 核心二进制 (easytier-core / easytier-cli)
#    并注入固件 files/usr/bin 目录
# 2. 下载 EasyTier 官方发布的 luci-app-easytier APK 安装包
#    并放入 packages 目录供 ImageBuilder 组装
# 若不需要此功能，直接删除本脚本并在 apk-custom-packages.sh 中移除对应配置即可
# ==============================================================================

set -e

echo "=== 正在执行 EasyTier 模块准备工作 ==="

mkdir -p files/usr/bin
mkdir -p /home/build/immortalwrt/packages

# 1. 获取并解压官方最新 EasyTier x86_64 核心程序
echo "正在检索 EasyTier 最新核心发布版本..."
EASYTIER_CORE_URL=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest \
  | grep "browser_download_url.*linux-x86_64.*\.zip" \
  | head -n1 \
  | cut -d '"' -f 4)

if [ -n "$EASYTIER_CORE_URL" ]; then
    echo "下载 EasyTier 核心: $EASYTIER_CORE_URL"
    wget -q "$EASYTIER_CORE_URL" -O /tmp/easytier.zip
    mkdir -p /tmp/easytier
    if command -v unzip >/dev/null 2>&1; then
        unzip -o -q /tmp/easytier.zip -d /tmp/easytier
    else
        python3 -m zipfile -e /tmp/easytier.zip /tmp/easytier
    fi
    find /tmp/easytier -type f -name "easytier-core" -exec cp -f {} files/usr/bin/ \;
    find /tmp/easytier -type f -name "easytier-cli" -exec cp -f {} files/usr/bin/ \;
    chmod +x files/usr/bin/easytier-core files/usr/bin/easytier-cli 2>/dev/null || true
    rm -rf /tmp/easytier /tmp/easytier.zip
    echo "EasyTier 核心文件 (easytier-core, easytier-cli) 已就绪"
else
    echo "错误：无法获取 EasyTier 核心下载地址"
    exit 1
fi

# 2. 获取适配版本的 luci-app-easytier 安装包 (25.12 为 apk，24.10 为 ipk)
echo "正在检索 luci-app-easytier 最新安装包..."
if command -v apk >/dev/null 2>&1 || grep -q "CONFIG_LINUX_6_12=y" .config 2>/dev/null; then
    PKG_EXT="apk"
else
    PKG_EXT="ipk"
fi

EASYTIER_LUCI_URL=$(curl -s https://api.github.com/repos/EasyTier/luci-app-easytier/releases/latest \
  | grep "browser_download_url.*${PKG_EXT}" \
  | head -n1 \
  | cut -d '"' -f 4)

if [ -n "$EASYTIER_LUCI_URL" ]; then
    echo "下载 luci-app-easytier (${PKG_EXT}): $EASYTIER_LUCI_URL"
    wget -q "$EASYTIER_LUCI_URL" -P /home/build/immortalwrt/packages/
    echo "luci-app-easytier 包已放入 packages 目录"
else
    echo "错误：无法获取 luci-app-easytier ${PKG_EXT} 下载地址"
    exit 1
fi

echo "=== EasyTier 模块准备完成 ==="
