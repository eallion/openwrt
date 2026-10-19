#!/bin/sh

# 99-custom.sh 就是 immortalwrt 固件首次启动时运行的脚本 位于固件内的 /etc/uci-defaults/99-custom.sh
LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >>$LOGFILE

# 设置默认防火墙规则，方便首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
# uci add dhcp domain
# uci set "dhcp.@domain[-1].name=time.android.com"
# uci set "dhcp.@domain[-1].ip=203.107.6.88"

# LAN 网络设置
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.0.1'
uci set network.lan.netmask='255.255.255.0'

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface 2>/dev/null

# 设置 SSH
uci set dropbear.@dropbear[0].Interface='lan'

uci commit

# 若安装了 dockerd 则设置 docker 的防火墙规则
if command -v dockerd >/dev/null 2>&1; then
    echo "检测到 Docker，正在配置防火墙规则..." >>$LOGFILE
    FW_FILE="/etc/config/firewall"

    uci delete firewall.docker 2>/dev/null

    for idx in $(uci show firewall | grep "=forwarding" | cut -d[ -f2 | cut -d] -f1 | sort -rn); do
        src=$(uci get firewall.@forwarding[$idx].src 2>/dev/null)
        dest=$(uci get firewall.@forwarding[$idx].dest 2>/dev/null)
        if [ "$src" = "docker" ] || [ "$dest" = "docker" ]; then
            uci delete firewall.@forwarding[$idx]
        fi
    done
    uci commit firewall

    cat <<EOF >>"$FW_FILE"

config zone 'docker'
  option input 'ACCEPT'
  option output 'ACCEPT'
  option forward 'ACCEPT'
  option name 'docker'
  list subnet '172.16.0.0/12'

config forwarding
  option src 'docker'
  option dest 'lan'

config forwarding
  option src 'docker'
  option dest 'wan'

config forwarding
  option src 'lan'
  option dest 'docker'
EOF
fi

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by Charles Chin"
if [ -f "$FILE_PATH" ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"
fi

exit 0
