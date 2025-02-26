#!/bin/sh

# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >>$LOGFILE
# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# LAN 网络设置
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.0.1'
uci set network.lan.netmask='255.255.255.0'

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置 SSH
uci set dropbear.@dropbear[0].Interface='lan'

uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by Charles Chin"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
