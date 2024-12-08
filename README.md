# Actions OpenWrt

Build OpenWrt using GitHub Actions

[![Build OpenWrt Lean](https://github.com/eallion/openwrt/actions/workflows/build-openwrt.yml/badge.svg?branch=main)](https://github.com/eallion/openwrt/actions/workflows/build-openwrt.yml)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Source

- https://github.com/openwrt/openwrt
- https://github.com/coolsnowwolf/lede
- https://github.com/fw876/helloworld
- https://github.com/Lienol/openwrt-package
- https://github.com/immortalwrt/immortalwrt
- https://github.com/immortalwrt/homeproxy

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/)

This repo only keeps the latest 5 releases.

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
- Generate `.config` files using [Immortalwrt](https://github.com/immortalwrt/immortalwrt) source code (You can change it through environment variables in the workflow file.)
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

# Make on local

### OS

Ubuntu / Debian / WSL ...

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
  g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
  libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano \
  ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
  python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs \
  upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

### Windows WSL Path

> https://openwrt.org/docs/guide-developer/toolchain/wsl

```bash
sudo tee -a /etc/wsl.conf << EOF > /dev/null
[interop]
appendWindowsPath = false
EOF
exit
```

### Clone

```bash
git clone git clone -b openwrt-23.05 --single-branch --filter=blob:none https://github.com/immortalwrt/immortalwrt
```

### Default Lan IP

```bash
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

### (Option) Download `.config`

```bash
rm .config
wget -O .config https://raw.githubusercontent.com/eallion/openwrt/refs/heads/main/immortalwrt-23.05.config
```

### Make

```bash
# make download -j32
# make V=s -j$(nproc)

bash make_immortalwrt.sh
```

### Regenerate config

```bash
rm -rf ./tmp && rm -rf .config
make menuconfig
make download -j8
make V=s -j$(nproc)
```

Then you can download firmware at [Releases](https://github.com/eallion/openwrt/releases/latest/) later.

### License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE) © P3TERX
