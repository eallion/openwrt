#!/bin/bash
#=============================================================
# https://github.com/eallion/openwrt
#=============================================================

# Clone Lean's lede
cd ~/Documents/
if [ ! -d "lede" ]; then
    sudo apt-get update
    sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync
    git clone https://github.com/coolsnowwolf/lede
else
    cd lede
    # git fetch --all
    # git reset --hard origin/master
    git status
    git add .
    git commit -m "$(TZ=UTC-8 date +"%Y-%m-%d"" ""%T"" UTC+0800")"
    git pull
    git submodule update
fi

cd ~/Documents/lede

# Uncomment a feed source
sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# Modify default IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Install feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Package Chin
cd package
if [ ! -d "chin" ]; then
    mkdir -p chin
fi
cd chin

# Add aliddns
if [ ! -d "luci-app-aliddns" ]; then
    git submodule add -b master https://github.com/chenhw2/luci-app-aliddns.git luci-app-aliddns
fi
    rm -rf ../lean/luci-app-aliddns
    cp -r luci-app-aliddns ../lean/luci-app-aliddns

# Add JD dailybonus
if [ ! -d "luci-app-jd-dailybonus" ]; then
    git submodule add -b master https://github.com/jerrykuku/luci-app-jd-dailybonus.git luci-app-jd-dailybonus
    rm -rf ../lean/luci-app-jd-dailybonus
    cp -r luci-app-jd-dailybonus ../lean/luci-app-jd-dailybonus
fi

# Add serverchan
if [ ! -d "luci-app-jd-serverchan" ]; then
    git submodule add -b master https://github.com/tty228/luci-app-serverchan.git luci-app-serverchan
fi
    rm -rf ../lean/luci-app-serverchan
    cp -r luci-app-serverchan ../lean/luci-app-serverchan

# Add AdGuardHome
if [ ! -d "luci-app-jd-adguardhome" ]; then
    git submodule add -b master https://github.com/rufengsuixing/luci-app-adguardhome.git luci-app-adguardhome
fi
    rm -rf ../lean/luci-app-adguardhome
    cp -r luci-app-adguardhome ../lean/luci-app-adguardhome

# Add autoipsetadder
if [ ! -d "luci-app-jd-autoipsetadder" ]; then
    git submodule add -b master https://github.com/rufengsuixing/luci-app-autoipsetadder.git luci-app-autoipsetadder
fi
    rm -rf ../lean/luci-app-autoipsetadder
    cp -r luci-app-autoipsetadder ../lean/luci-app-autoipsetadder

# Add openclash
if [ ! -d "OpenClash" ]; then
    git submodule add -b master https://github.com/vernesong/OpenClash.git OpenClash
fi
    cd OpenClash
    rm -rf ../lean/luci-app-openclash
    cp -r luci-app-openclash ../../lean/luci-app-openclash
    cd ..

# Download config
cd ~/Documents/lede
rm -rf ./tmp && rm -rf .config
if [ ! -d "openwrt" ]; then
    git submodule add -b main https://github.com/eallion/openwrt.git openwrt
else
    git submodule update
fi
cp openwrt/.config .config
echo " "
echo " "
echo "======================================"
echo "= Done! $(TZ=UTC-8 date +"%Y-%m-%d"" ""%T"" UTC+0800") ="
echo "======================================"
echo " "
echo " "