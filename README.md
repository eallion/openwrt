# OpenWrt(ImmortalWrt) ImageBuilder

Build ImmortalWrt quickly using `immortalwrt/imagebuilder` in GitHub Actions.

[![GitHub](https://img.shields.io/github/license/wukongdaily/AutoBuildImmortalWrt.svg?label=LICENSE&logo=github&logoColor=%20)](https://github.com/wukongdaily/AutoBuildImmortalWrt/blob/master/LICENSE) [![build-x86-64-immortalwrt-24.10](https://github.com/eallion/openwrt/actions/workflows/build-x86-64-24.10.yml/badge.svg?branch=wukongdaily%2FAutoBuildImmortalWrt)](https://github.com/eallion/openwrt/actions/workflows/build-x86-64-24.10.yml)

### 🤔 这是什么？

它是一个工作流，可快速构建带 Docker 且支持自定义固件大小的 ImmortalWrt。

> 1、支持自定义固件大小 默认 `4GB`  
> 2、支持预安装 `docker`（可选）  
> 3、默认 LAN 口 IP 为 `192.168.0.1`  
> 4、可以通过 `files/etc/uci-defaults/99-custom.sh` 配置和调整  
> 5、可以通过 `shell/custom-packages.sh` 添加或删除第三方插件  
> 6、可以通过 `x86-64/build.sh` 添加删除插件  
> 7、`shell/cloudflared.sh` 添加 Cloudflared 二进制文件  

### ImmortalWrt 软件仓库镜像

- https://help.mirrors.cernet.edu.cn/immortalwrt/

### 如何查询都有哪些插件？

- https://mirrors.sjtug.sjtu.edu.cn/immortalwrt/releases/24.10.5/packages/x86_64/luci/
- https://mirror.nju.edu.cn/immortalwrt/releases/24.10.5/packages/x86_64/luci/

### Source

- https://github.com/openwrt/openwrt
- https://github.com/coolsnowwolf/lede
- https://github.com/immortalwrt/immortalwrt
- https://github.com/fw876/helloworld
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
