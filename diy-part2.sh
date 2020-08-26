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
sed -i 's/192.168.1.1/192.168.0.2/g' package/base-files/files/bin/config_generate

# Add aliddns
git clone https://github.com/chenhw2/luci-app-aliddns.git package/lean/luci-app-aliddns
# git clone package/lean/luci-app-aliddns https://github.com/chenhw2/luci-app-aliddns.git master

# Add JD dailybonus
git clone https://github.com/jerrykuku/node-request.git package/lean/node-request
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/lean/luci-app-jd-dailybonus
# git subtree add --prefix=package/lean/node-request https://github.com/jerrykuku/node-request.git master
# git subtree add --prefix=package/lean/luci-app-jd-dailybonus https://github.com/jerrykuku/luci-app-jd-dailybonus.git master

# Add serverchan
git clone https://github.com/tty228/luci-app-serverchan.git package/lean/luci-app-serverchan
# git subtree add --prefix=package/lean/luci-app-serverchan https://github.com/tty228/luci-app-serverchan.git master

# Add openclash
git clone --single-branch --branch master https://github.com/vernesong/OpenClash.git
cd OpenClash
mv luci-app-openclash ../package/lean/luci-app-openclash
cd ..
rm -rf OpenClash

# Change wrtbwmon
git clone --single-branch --branch master  https://github.com/brvphoenix/luci-app-wrtbwmon.git
cd luci-app-wrtbwmon
mv luci-app-wrtbwmon ../package/lean/luci-app-wrtbwmon
cd ..
rm -rf luci-app-wrtbwmon