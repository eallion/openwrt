# OpenWrt Builder

Build OpenWrt using GitHub Actions.

[![OpenWrt Builder](https://github.com/eallion/openwrt/actions/workflows/build-immortalwrt.yml/badge.svg?branch=main)](https://github.com/eallion/openwrt/actions/workflows/build-immortalwrt.yml)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Source

- https://github.com/openwrt/openwrt
- https://github.com/coolsnowwolf/lede
- https://github.com/fw876/helloworld
- https://github.com/Lienol/openwrt-package
- https://github.com/immortalwrt/immortalwrt
- https://github.com/immortalwrt/homeproxy

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/download/openwrt-x86-64-generic-squashfs-combined-efi.img.gz)

This repo only keeps the latest 5 releases.

### Check sha256sums

Download the [`.sha256`](https://github.com/eallion/openwrt/releases/latest/download/openwrt-x86-64-generic-squashfs-combined-efi.img.gz.sha256) file. Make sure the sha256sums file and img file in a same folder.

```bash
sha256sum -c openwrt-x86-64-generic-squashfs-combined-efi.img.gz.sha256 --ignore-missing 
```

or find sha256sums on the release tag note, check it manual

```bash
echo "bf69a9ae42825a76c449699f393b8aa35216f3ffef428ae851d76ce4386bd3c3 *openwrt-x86-64-generic-squashfs-combined.img.gz" | shasum -a 256 --check
```

Make sure its `OK` before upload it.

# Build your Openwrt

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [LEDE](https://github.com/coolsnowwolf/lede) source code (You can change it through environment variables in the workflow file.)
- Push `.config` file to the GitHub repository, and the build starts automatically. Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` (if `true`) button in the upper right corner of the Actions page to download the binaries. Or download on the release (if `true`) page.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

### OS

Ubuntu / Debian / WSL ...

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache clang cmake cpio curl device-tree-compiler flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libncurses-dev libpython3-dev libreadline-dev \
libssl-dev libtool llvm lrzsz genisoimage msmtp ninja-build p7zip p7zip-full patch pkgconf python3 \
python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

### (Option) Windows WSL Path

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
git clone https://github.com/coolsnowwolf/lede
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

```bash
make menuconfig
```

### (Option) Download `.config`

```bash
rm .config
wget -O .config https://raw.githubusercontent.com/eallion/openwrt/refs/heads/main/.config
```

### Make

```bash
# make download -j32
# make V=s -j$(nproc)

bash make_lede.sh
```

### Regenerate config

```bash
rm -rf ./tmp && rm -rf .config
make menuconfig
make download -j8
make V=s -j$(nproc)
```

Then you can find firmware at `openwrt/bin/targets/x86/64/` later.

### License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE) © P3TERX
