#!/bin/bash
#============================================================
# https://github.com/eallion/OpenWrt
#============================================================

cd package/chin

# Update aliddns
cd luci-app-aliddns
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/luci-app-aliddns
cp -r luci-app-aliddns ../lean/luci-app-aliddns

# Update JD dailybonus
cd node-request
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/node-request
cp -r node-request ../lean/node-request 
cd luci-app-jd-dailybonus
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/luci-app-jd-dailybonus
cp -r luci-app-jd-dailybonus ../lean/luci-app-jd-dailybonus


# Update serverchan
cd luci-app-serverchan
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/luci-app-serverchan
cp -r luci-app-serverchan ../lean/luci-app-serverchan

# Update openclash
cd OpenClash
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/luci-app-openclash
cp -r OpenClash/luci-app-openclash ../lean/luci-app-openclash

# Update wrtbwmon
cd luci-app-wrtbwmon
git fetch --all
git reset --hard origin/master
git pull
cd ..
rm -rf ../lean/luci-app-wrtbwmon
cp -r luci-app-wrtbwmon/luci-app-wrtbwmon ../lean/luci-app-wrtbwmon