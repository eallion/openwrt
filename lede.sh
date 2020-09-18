#!/bin/bash
#=============================================================
# https://github.com/eallion/openwrt
#=============================================================

# Clone Lean's lede
cd ~/Documents/
rm -rf lede
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync
git clone https://github.com/coolsnowwolf/lede
cd lede

# Uncomment a feed source
sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# Modify default IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Install feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# Package Chin
mkdir -p package/chin
cd package/chin

# Add aliddns
# git clone https://github.com/chenhw2/luci-app-aliddns.git -b master
git submodule add -b master https://github.com/chenhw2/luci-app-aliddns.git luci-app-aliddns
rm -rf ../lean/luci-app-aliddns
cp -r luci-app-aliddns ../lean/luci-app-aliddns

# Add JD dailybonus
# git clone https://github.com/jerrykuku/node-request.git -b master
# git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git -b master
# git submodule add -b master https://github.com/jerrykuku/node-request.git node-request
git submodule add -b master https://github.com/jerrykuku/luci-app-jd-dailybonus.git luci-app-jd-dailybonus
rm -rf ../lean/node-request
cp -r node-request ../lean/node-request
rm -rf ../lean/luci-app-jd-dailybonus
cp -r luci-app-jd-dailybonus ../lean/luci-app-jd-dailybonus

# Add serverchan
# git clone https://github.com/tty228/luci-app-serverchan.git -b master
git submodule add -b master https://github.com/tty228/luci-app-serverchan.git luci-app-serverchan
rm -rf ../lean/luci-app-serverchan
cp -r luci-app-serverchan ../lean/luci-app-serverchan

# Add AdGuardHome
git submodule add -b master https://github.com/rufengsuixing/luci-app-adguardhome.git luci-app-adguardhome
rm -rf ../lean/luci-app-adguardhome
cp -r luci-app-adguardhome ../lean/luci-app-adguardhome

# Add autoipsetadder
git submodule add -b master https://github.com/rufengsuixing/luci-app-autoipsetadder.git luci-app-autoipsetadder
rm -rf ../lean/luci-app-autoipsetadder
cp -r luci-app-autoipsetadder ../lean/luci-app-autoipsetadder

# Add openclash
# git clone https://github.com/vernesong/OpenClash.git -b master
git submodule add -b master https://github.com/vernesong/OpenClash.git OpenClash
cd OpenClash
rm -rf ../lean/luci-app-openclash
cp -r luci-app-openclash ../../lean/luci-app-openclash
cd ..

# Download config
cd ../..
rm -rf ./tmp && rm -rf .config
# git clone https://github.com/eallion/openwrt.git
git submodule add -b main https://github.com/eallion/openwrt.git openwrt
cd openwrt
cp .config ../.config
cp update_app.sh ../update_app.sh
rm -rf openwrt

echo "=============================="
echo "Done!"
echo "=============================="