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

# Add openclash
#git clone --single-branch --branch master https://github.com/vernesong/OpenClash.git
#cd OpenClash
#mv luci-app-openclash ../package/lean/luci-app-openclash
#cd ..

# Add luci-theme-neobird
#git clone https://github.com/thinktip/luci-theme-neobird.git package/lean/luci-theme-neobird

# Add luci-app-cloudflarespeedtest
#git clone https://github.com/immortalwrt-collections/openwrt-cdnspeedtest package/openwrt-cdnspeedtest
#git clone https://github.com/mingxiaoyu/luci-app-cloudflarespeedtest package/luci-app-cloudflarespeedtest
#git clone https://github.com/eallion/luci-app-cloudflarespeedtest package/luci-app-cloudflarespeedtest

# Add luci-app-nginx-manager
git clone https://github.com/eallion/luci-app-nginx-manager package/luci-app-nginx-manager

# Add luci-app-mosdns
# find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f
# find ./ | grep Makefile | grep mosdns | xargs rm -f

# git clone https://github.com/eallion/luci-app-mosdns -b v5 package/mosdns
# git clone https://github.com/eallion/v2ray-geodata package/v2ray-geodata