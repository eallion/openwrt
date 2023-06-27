#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Add luci-app-alist
git clone https://github.com/sbwml/luci-app-alist package/alist

# Add luci-app-easymesh
git clone https://github.com/ntlf9t/luci-app-easymesh package/luci-app-easymesh

# Add luci-app-mosdns
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f
find ./ | grep Makefile | grep mosdns | xargs rm -f
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# Add luci-app-pushbot
git clone https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot