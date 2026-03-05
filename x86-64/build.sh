#!/bin/bash
# Log file for debugging
source shell/custom-packages.sh
echo "第三方软件包：$CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为：$PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

if [ -z "$CUSTOM_PACKAGES" ]; then
    echo "⚪️ 未选择 任何第三方软件包"
    else
    # ============= 同步第三方插件库==============
    # 同步第三方软件仓库 run/ipk
    echo "🔄 正在同步第三方软件仓库 Cloning run file repo..."
    git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-run-repo

    # 拷贝 run/x86 下所有 run 文件和 ipk 文件 到 extra-packages 目录
    mkdir -p /home/build/immortalwrt/extra-packages
    cp -r /tmp/store-run-repo/run/x86/* /home/build/immortalwrt/extra-packages/

    echo "✅ Run files copied to extra-packages:"
    ls -lh /home/build/immortalwrt/extra-packages/*.run
    # 解压并拷贝 ipk 到 packages 目录
    sh shell/prepare-packages.sh
    ls -lah /home/build/immortalwrt/packages/
fi

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ============= ImmortalWrt 仓库内的插件==============
# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES luci-app-autoreboot"
# PACKAGES="$PACKAGES luci-app-cloudflared"
PACKAGES="$PACKAGES luci-app-ddns-go"
PACKAGES="$PACKAGES luci-app-diskman"
PACKAGES="$PACKAGES luci-app-filebrowser"
PACKAGES="$PACKAGES luci-app-homeproxy"
PACKAGES="$PACKAGES luci-app-netdata"
# PACKAGES="$PACKAGES luci-app-p910nd"
PACKAGES="$PACKAGES luci-app-ttyd"
PACKAGES="$PACKAGES luci-app-uhttpd"
PACKAGES="$PACKAGES luci-app-vlmcsd"
PACKAGES="$PACKAGES luci-app-wol"
PACKAGES="$PACKAGES luci-i18n-autoreboot-zh-cn"
# PACKAGES="$PACKAGES luci-i18n-cloudflared-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ddns-go-zh-cn"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-zh-cn"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES luci-i18n-netdata-zh-cn"
# PACKAGES="$PACKAGES luci-i18n-p910nd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-uhttpd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-vlmcsd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-wol-zh-cn"
# OpenSSH SFTP Server
PACKAGES="$PACKAGES openssh-sftp-server"
# Git
PACKAGES="$PACKAGES git git-http"
# 默认没有中文包
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
# 打印机组件
PACKAGES="$PACKAGES avahi-dbus-daemon dbus kmod-usb-printer p910nd usbutils"
# 增加几个必备组件 方便用户安装 iStore
PACKAGES="$PACKAGES fdisk cfdisk"
PACKAGES="$PACKAGES script-utils"
# ======== shell/custom-packages.sh =======
# 合并 ImmortalWrt 仓库以外的第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

# ======== shell/cloudflared.sh =======
# 替换最新版本的 Cloudflared 二进制文件

# sh shell/cloudflared.sh
sh shell/ddns-go.sh

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
