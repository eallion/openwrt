#!/bin/bash
#=============================================================
# https://github.com/eallion/openwrt
#=============================================================

# Clone Lean's lede
cd ~/Documents/
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync
git clone https://github.com/coolsnowwolf/lede
cd lede

# Uncomment a feed source
sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# Modify default IP
sed -i 's/192.168.1.1/192.168.0.2/g' package/base-files/files/bin/config_generate

# Install feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# Package Chin
mkdir -p package/chin
cd package/chin

# Add aliddns
git clone https://github.com/chenhw2/luci-app-aliddns.git -b master
cd luci-app-aliddns
rm -rf ../lean/luci-app-aliddns
cp -r luci-app-aliddns ../lean/luci-app-aliddns
cd ..

# Add JD dailybonus
git clone https://github.com/jerrykuku/node-request.git -b master
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git -b master
cd node-request
rm -rf ../lean/node-request
cp -r node-request ../lean/node-request
cd ..
cd luci-app-jd-dailybonus
rm -rf ../lean/luci-app-jd-dailybonus
cp -r luci-app-jd-dailybonus ../lean/luci-app-jd-dailybonus
cd ..

# Add serverchan
git clone https://github.com/tty228/luci-app-serverchan.git -b master
cd luci-app-serverchan
rm -rf ../lean/luci-app-serverchan
cp -r luci-app-serverchan ../lean/luci-app-serverchan
cd ..

# Add openclash
git clone https://github.com/vernesong/OpenClash.git -b master
cd OpenClash
rm -rf ../lean/luci-app-openclash
mv luci-app-openclash ../lean/luci-app-openclash
cd ..

# Change wrtbwmon
git clone https://github.com/brvphoenix/luci-app-wrtbwmon.git -b master
cd luci-app-wrtbwmon
rm -rf ../package/lean/luci-app-wrtbwmon
mv luci-app-wrtbwmon/luci-app-wrtbwmon ../package/lean/luci-app-wrtbwmon
cd ..

# Download config
rm -rf ./tmp && rm -rf .config
git clone https://github.com/eallion/openwrt.git
cd openwrt
cp .config ../.config