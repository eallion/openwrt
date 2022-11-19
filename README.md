# Actions OpenWrt

Build OpenWrt using GitHub Actions

![Build OpenWrt](https://github.com/eallion/openwrt/workflows/Build%20OpenWrt/badge.svg)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Source

- https://github.com/coolsnowwolf/lede
- https://github.com/openwrt/openwrt
- https://github.com/fw876/helloworld
- https://github.com/Lienol/openwrt-package
- [https://github.com/immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt/tree/openwrt-21.02)

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/)

This repo only keeps the lastest 5 releases.

### Check sha256sums

Download the [sha256sums](https://github.com/eallion/openwrt/releases/latest/) file.

Make sure the sha256sums file and img file in a same folder.

```shell
sha256sum -c sha256sums --ignore-missing 
```

or

```shell
echo "bf69a9ae42825a76c449699f393b8aa35216f3ffef428ae851d76ce4386bd3c3 *openwrt-x86-64-generic-squashfs-combined.img.gz" | shasum -a 256 --check
```

Make sure its `OK` before upload it.

### Usage

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [ImmortalWrt](https://github.com/immortalwrt/immortalwrt/tree/openwrt-21.02) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

# Make on local

### OS

I make Openwrt on Ubuntu / Debian / WSL ...
(Ubuntu 20.04 LTS x86 is recommended)

```shell
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
```

### Clone

```shell
cd ~
git clone https://github.com/coolsnowwolf/lede
```

### Add [@fw876/helloworld](https://github.com/fw876/helloworld)

```shell
cd ~/lede
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default
```

### Install feeds
```shell
./scripts/feeds update -a && ./scripts/feeds install -a
```

### Change default IP:
```shell
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate
```

### Generate config
```
make menuconfig
```

### (Option) Download`.config`

```shell
cd ~/lede
rm .config
wget -c https://raw.githubusercontent.com/eallion/openwrt/main/.config
```

### Make:
```shell
make -j8 download V=s
make -j$(($(nproc) + 1)) V=s
```

### Regenerate `.config`
```shell
rm -rf ./tmp && rm -rf .config
```
```shell
make menuconfig
```
Remake on local
```shell
make -j8 download V=s
make -j$(($(nproc) + 1)) V=s
```

// or:

Push `.config` to [eallion/openwrt](https://github.com/eallion/openwrt) make on GitHub Actions
```shell
rm ~/openwrt/.config
cp ~/lede/.config ~/openwrt/
cd ~/openwrt
git add .
git commit -m "message"
git push
```
Then you can download firmware at [Releases](https://github.com/eallion/openwrt/releases/latest/) later.

# Customs

##### 1. Add [@fw876/helloworld](https://github.com/fw876/helloworld)

Uncommnet `#src-git` to use
```shell
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default
```

*Option: [@Lienol/openwrt-package](https://github.com/Lienol/openwrt-package)

```
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
```

##### 2. Default IP

> 192.168.0.1


Change default IP:

```shell
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate
```

##### 3. Image's setting

- Set 160MB root filesystem partigion size
- ~~GZip images~~	

##### 4. Luci apps

- luci-app-ssr-plus	 
- ……

##### 5. Others

- Enable Nginx for luci and web service
- Enable openssh-sftp-server
- Enable curl and wget
- Enable drill for DDNS
- ~~Enable Docker & Docker Compose~~
- ~~Enable OpenClash~~
- ......

### Acknowledgments

- [Microsoft](https://www.microsoft.com)
- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub](https://github.com)
- [GitHub Actions](https://github.com/features/actions)
- [tmate](https://github.com/tmate-io/tmate)
- [mxschmitt/action-tmate](https://github.com/mxschmitt/action-tmate)
- [csexton/debugger-action](https://github.com/csexton/debugger-action)
- [Cisco](https://www.cisco.com/)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [Lean's OpenWrt](https://github.com/coolsnowwolf/lede)
- [Cowtransfer](https://cowtransfer.com)
- [WeTransfer](https://wetransfer.com/)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)

### License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE) © P3TERX
