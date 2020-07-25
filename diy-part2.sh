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

# Add serverchan
git clone https://github.com/tty228/luci-app-serverchan.git package/lean/luci-app-serverchan

# Add openclash
git clone --single-branch --branch master https://github.com/vernesong/OpenClash.git
cd OpenClash
mv luci-app-openclash ../package/lean/luci-app-openclash

# Add xlnetacc
rm -rf package/lean/luci-app-xlnetacc
git clone https://github.com/awesome-openwrt/luci-app-xlnetacc.git package/lean/luci-app-xlnetacc

# Add JD dailybonus
git clone https://github.com/jerrykuku/node-request.git package/lean/node-request
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/lean/luci-app-jd-dailybonus