#!/bin/bash
#============================================================
# https://github.com/eallion/OpenWrt
#============================================================

git submodule update

# Update aliddns
rm -rf package/lean/luci-app-aliddns
cp -r package/chin/luci-app-aliddns package/lean/luci-app-aliddns

# Update JD dailybonus
rm -rf package/lean/node-request
cp -r package/chin/node-request package/lean/node-request 
rm -rf package/lean/luci-app-jd-dailybonus
cp -r package/chin/luci-app-jd-dailybonus package/lean/luci-app-jd-dailybonus

# Update serverchan
rm -rf package/lean/luci-app-serverchan
cp -r package/chin/luci-app-serverchan package/lean/luci-app-serverchan

# Update openclash
rm -rf package/lean/luci-app-openclash
cp -r package/chin/OpenClash/luci-app-openclash package/lean/luci-app-openclash