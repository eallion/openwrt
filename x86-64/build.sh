#!/bin/bash
# 初始化第三方包变量，确保未显式开启时为空
CUSTOM_PACKAGES=""

# 判断版本是否属于 24.10 系
IS_2410=0
if [[ "$BUILD_VERSION" =~ ^24\.10 ]]; then
    IS_2410=1
fi

if [ "$IS_2410" -eq 1 ]; then
    if [ -f shell/custom-packages.sh ]; then
        source shell/custom-packages.sh
    fi
else
    if [ -f shell/apk-custom-packages.sh ]; then
        source shell/apk-custom-packages.sh
    fi
fi
if [ -f shell/switch_repository.sh ]; then
    source shell/switch_repository.sh
fi

echo "第三方软件包: $CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

if [ -z "${CUSTOM_PACKAGES// }" ]; then
    echo "未选择任何第三方软件包"
else
    mkdir -p /home/build/immortalwrt/extra-packages
    if [ "$IS_2410" -eq 1 ]; then
        echo "正在同步 24.10 第三方 IPK 软件仓库..."
        git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-repo
        cp -r /tmp/store-repo/run/x86/* /home/build/immortalwrt/extra-packages/
        echo "文件已拷贝至 extra-packages，开始解压整理 IPK..."
        sh shell/prepare-packages.sh
    else
        echo "正在同步 25.12 第三方 APK 软件仓库..."
        git clone --depth=1 https://github.com/wukongdaily/apk.git /tmp/store-apk-repo
        cp -r /tmp/store-apk-repo/run/x86/* /home/build/immortalwrt/extra-packages/
        echo "文件已拷贝至 extra-packages，开始解压整理 APK..."
        sh shell/apk-prepare-packages.sh
    fi
    ls -lah /home/build/immortalwrt/packages/
fi

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ============= ImmortalWrt 仓库内的插件 =============
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES irqbalance"
PACKAGES="$PACKAGES luci-app-autoreboot"
PACKAGES="$PACKAGES luci-app-homeproxy"
PACKAGES="$PACKAGES luci-app-uhttpd"
PACKAGES="$PACKAGES luci-app-vlmcsd"
PACKAGES="$PACKAGES luci-i18n-autoreboot-zh-cn"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES luci-i18n-uhttpd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-vlmcsd-zh-cn"
# OpenSSH SFTP Server
PACKAGES="$PACKAGES openssh-sftp-server"
# Git
PACKAGES="$PACKAGES git git-http"
# TCP BBR
PACKAGES="$PACKAGES kmod-tcp-bbr"
# ACME
# PACKAGES="$PACKAGES acme acme-acmesh acme-acmesh-dnsapi luci-app-acme luci-i18n-acme-zh-cn"
# 打印机组件
# PACKAGES="$PACKAGES avahi-dbus-daemon dbus kmod-usb-printer p910nd usbutils"
# 增加几个必备组件 方便用户安装 iStore
PACKAGES="$PACKAGES fdisk cfdisk"
PACKAGES="$PACKAGES script-utils"

# 合并第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "已添加 Docker 插件: luci-i18n-dockerman-zh-cn"
fi

# 若构建 openclash 则补充内核与规则库
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "已选择 luci-app-openclash，正在下载内核与规则库..."
    mkdir -p files/etc/openclash/core
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v1.tar.gz"
    wget -qO- $META_URL | tar xOvz > files/etc/openclash/core/clash_meta
    chmod +x files/etc/openclash/core/clash_meta
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
    if [ "$IS_2410" -eq 1 ]; then
        URL=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases/latest \
          | grep "browser_download_url.*ipk" \
          | head -n1 \
          | cut -d '"' -f 4)
        if [ -n "$URL" ]; then
            echo "下载 OpenClash 最新 ipk: $URL"
            wget "$URL" -P /home/build/immortalwrt/packages/
        fi
    else
        URL=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases/latest \
          | grep "browser_download_url.*apk" \
          | head -n1 \
          | cut -d '"' -f 4)
        if [ -n "$URL" ]; then
            echo "下载 OpenClash 最新 apk: $URL"
            wget "$URL" -P /home/build/immortalwrt/packages/
        fi
    fi
fi

# 若构建 ssr-plus 则补充 mihomo 内核
if echo "$PACKAGES" | grep -q "luci-app-ssr-plus"; then
    echo "已选择 luci-app-ssr-plus，正在下载 mihomo 内核..."
    mkdir -p files/usr/bin
    MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-compatible-v1.19.24.gz"
    wget -qO- "$MIHOMO_URL" | gzip -dc > files/usr/bin/mihomo
    chmod +x files/usr/bin/mihomo
    echo "已下载 mihomo 内核"
fi

# 替换最新版本的 Cloudflared / DDNS-GO 二进制文件（仅在选择对应插件时下载）
# if echo "$PACKAGES" | grep -q "cloudflared"; then
#     [ -f shell/cloudflared.sh ] && sh shell/cloudflared.sh
# fi
if echo "$PACKAGES" | grep -q "ddns-go"; then
    if [ -f shell/ddns-go.sh ]; then
        sh shell/ddns-go.sh
    fi
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
