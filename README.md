# AutoBuildImmortalWrt

[![GitHub](https://img.shields.io/github/license/wukongdaily/AutoBuildImmortalWrt.svg?label=LICENSE&logo=github&logoColor=%20)](https://github.com/wukongdaily/AutoBuildImmortalWrt/blob/master/LICENSE)
![GitHub Stars](https://img.shields.io/github/stars/wukongdaily/AutoBuildImmortalWrt.svg?style=flat&logo=appveyor&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/wukongdaily/AutoBuildImmortalWrt.svg?style=flat&logo=appveyor&label=Forks&logo=github) [![Github](https://img.shields.io/badge/RELEASE:AutoBuildImmortalWrt-123456?logo=github&logoColor=fff&labelColor=green&style=flat)](https://github.com/wukongdaily/AutoBuildImmortalWrt/releases) [![Bilibili](https://img.shields.io/badge/Bilibili-123456?logo=bilibili&logoColor=fff&labelColor=fb7299)](https://www.bilibili.com/video/BV1EG6VYCER3) [![操作步骤](https://img.shields.io/badge/YouTube-123456?logo=youtube&labelColor=ff0000)](https://youtu.be/xIVtUwZR6U0)

## 🤔 这是什么？

它是一个工作流。可快速构建 带 docker 且支持自定义固件大小的 immortalWrt
> 1、支持自定义固件大小 默认 1GB <br>
> 2、支持预安装 docker（可选）<br>
> 3、默认 LAN 口 IP 为 192.168.0.1
> 4、可以通过 `99-custom.sh` 配置和调整

## 如何查询都有哪些插件？

https://mirrors.sjtug.sjtu.edu.cn/immortalwrt/releases/23.05.4/packages/aarch64_cortex-a53/luci/ <br>
https://mirrors.sjtug.sjtu.edu.cn/immortalwrt/releases/23.05.4/packages/x86_64/luci/

## 该固件默认属性？(必读)

- 该固件刷入单网口设备默认采用 DHCP 模式，自动获得 ip。类似 NAS 的做法
- 该固件刷入多网口设备默认 WAN 口采用 DHCP 模式，LAN 口 ip 为 192.168.100.1
- 综合上述特点，单网口应该先接路由器，先在路由器查看一下它的 ip 再访问。
- 上述特点 你都可以通过 `99-custom.sh` 配置和调整

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
- https://github.com/wukongdaily/AutoBuildImmortalWrt

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/download/immortalwrt-x86-64-generic-squashfs-combined-efi.img.gz)

This repo only keeps the latest 5 releases.

### Check sha256sums

Download the [`.sha256`](https://github.com/eallion/openwrt/releases/latest/download/immortalwrt-x86-64-generic-squashfs-combined-efi.img.gz.sha256) file. Make sure the sha256sums file and img file in a same folder.

```bash
sha256sum -c immortalwrt-x86-64-generic-squashfs-combined-efi.img.gz.sha256 --ignore-missing 
```

or find sha256sums on the release tag note, check it manual

```bash
echo "bf69a9ae42825a76c449699f393b8aa35216f3ffef428ae851d76ce4386bd3c3 *openwrt-x86-64-generic-squashfs-combined.img.gz" | shasum -a 256 --check
```

Make sure its `OK` before upload it.

# Build your Openwrt

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [Immortalwrt](https://github.com/immortalwrt/immortalwrt) source code (You can change it through environment variables in the workflow file.)
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
  bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
  g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
  libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano \
  ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
  python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs \
  upx-ucl unzip vim wget xmlto xxd zlib1g-dev
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
git clone -b openwrt-23.05 --single-branch --filter=blob:none https://github.com/immortalwrt/immortalwrt
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

bash make_immortalwrt.sh
```

### Regenerate config

```bash
rm -rf ./tmp && rm -rf .config
make menuconfig
make download -j8
make V=s -j$(nproc)
```

Then you can find firmware at `immortalwrt/bin/targets/x86/64/` later.

## ❤️其它 GitHub Action 项目推荐🌟 （建议收藏）⬇️

https://github.com/wukongdaily/RunFilesBuilder<br>
https://github.com/wukongdaily/DockerTarBuilder

# 🌟鸣谢

### https://github.com/immortalwrt

### License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE) © P3TERX
