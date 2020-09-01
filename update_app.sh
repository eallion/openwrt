#!/bin/bash
#============================================================
# https://github.com/eallion/OpenWrt
#============================================================

git submodule update

# Update aliddns
rm -rf ../lean/luci-app-aliddns
cp -r luci-app-aliddns ../lean/luci-app-aliddns

# Update JD dailybonus
rm -rf ../lean/node-request
cp -r node-request ../lean/node-request 
rm -rf ../lean/luci-app-jd-dailybonus
cp -r luci-app-jd-dailybonus ../lean/luci-app-jd-dailybonus

# Update serverchan
rm -rf ../lean/luci-app-serverchan
cp -r luci-app-serverchan ../lean/luci-app-serverchan

# Update openclash
rm -rf ../lean/luci-app-openclash
cp -r OpenClash/luci-app-openclash ../lean/luci-app-openclash

# Update wrtbwmon
rm -rf ../lean/luci-app-wrtbwmon
cp -r luci-app-wrtbwmon/luci-app-wrtbwmon ../lean/luci-app-wrtbwmon