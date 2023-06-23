# Actions OpenWrt

Build OpenWrt using GitHub Actions

![Build OpenWrt](https://github.com/eallion/openwrt/workflows/Build%20OpenWrt/badge.svg)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Source

- <https://github.com/coolsnowwolf/lede>
- <https://github.com/openwrt/openwrt>
- <https://github.com/fw876/helloworld>
- <https://github.com/Lienol/openwrt-package>
- [https://github.com/immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt/tree/openwrt-23.05)

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
- Generate `.config` files using [ImmortalWrt](https://github.com/immortalwrt/immortalwrt/tree/openwrt-21.02) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

# Make on local

### OS

I make Openwrt on Ubuntu / Debian / WSL ...

```bash
sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.eu.org/init_build_environment.sh)'
```

### Clone

```bash
git clone -b openwrt-23.05 --single-branch --filter=blob:none https://github.com/immortalwrt/immortalwrt
```

### Custom

```bash
# Modify default IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Add luci-app-alist
git clone https://github.com/sbwml/luci-app-alist package/alist

# Add luci-app-easymesh
git clone https://github.com/ntlf9t/luci-app-easymesh package/luci-app-easymesh

# Add luci-app-mosdns
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f
find ./ | grep Makefile | grep mosdns | xargs rm -f
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# Add luci-app-pushbot
git clone https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot
```

### Install feeds

```bash
./scripts/feeds update -a && ./scripts/feeds install -a
```

### Generate config

```
make menuconfig
```

### (Option) Download`.config`

```bash
cd ~/immortalwrt
rm .config
wget -O .config https://raw.githubusercontent.com/eallion/openwrt/main/immortalwrt.config 
```

### Make

```bash
make -j8 download V=s
make -j$(($(nproc) + 1)) V=s
```

### Regenerate `.config`

```bash
rm -rf ./tmp && rm -rf .config
```

```bash
make menuconfig
```

Remake on local

```bash
make -j8 download V=s
make -j$(($(nproc) + 1)) V=s
```

// or:

Push `.config` to [eallion/openwrt](https://github.com/eallion/openwrt) make Openwrt on GitHub Actions

```bash
rm ~/openwrt/.config
cp ~/immortalwrt/.config ~/openwrt/
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
