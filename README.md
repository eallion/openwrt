# Actions OpenWrt

Build OpenWrt using GitHub Actions

![Build OpenWrt](https://github.com/eallion/openwrt/workflows/Build%20OpenWrt/badge.svg)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Source

- <https://github.com/coolsnowwolf/lede>
- <https://github.com/openwrt/openwrt>
- <https://github.com/fw876/helloworld>
- <https://github.com/Lienol/openwrt-package>
- <https://github.com/immortalwrt/immortalwrt>
-

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/)

This repo only keeps the lastest 5 releases.

### Check sha256sums

Download the [sha256sums](https://github.com/eallion/openwrt/releases/latest/) file.

Make sure the sha256sums file and img file in a same folder.

```bash
sha256sum -c sha256sums --ignore-missing 
```

or

```bash
echo "bf69a9ae42825a76c449699f393b8aa35216f3ffef428ae851d76ce4386bd3c3 *openwrt-x86-64-generic-squashfs-combined.img.gz" | shasum -a 256 --check
```

Make sure its `OK` before upload it.

### Usage

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [LEDE](https://github.com/coolsnowwolf/lede) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

# Make on local

### OS

I make Openwrt on Ubuntu / Debian / WSL ...

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
vim wget xmlto xxd zlib1g-dev
```

### Clone

```bash
git clone https://github.com/coolsnowwolf/lede
```

### Custom

```bash
# Modify default IP
sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate
```

### Install feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### Generate config

```
make menuconfig
```

### (Option) Download`.config`

```bash
cd ~/lede
rm .config
wget -O .config https://raw.githubusercontent.com/eallion/openwrt/main/.config 
```

### Make

```bash
make download -j8
make V=s -j$(nproc)
```

### Remake

```bash
cd lede
git pull
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make download -j8
make V=s -j$(nproc)
```

### Regenerate config

```bash
rm -rf ./tmp && rm -rf .config
make menuconfig
make download -j8
make V=s -j$(nproc)
```

// or:

Push `.config` to [eallion/openwrt](https://github.com/eallion/openwrt) make Openwrt on GitHub Actions

```bash
rm ~/openwrt/.config
cp ~/lede/.config ~/openwrt/
cd ~/openwrt
git add .
git commit -m "chore: update config"
git push
```

Then you can download firmware at [Releases](https://github.com/eallion/openwrt/releases/latest/) later.

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
