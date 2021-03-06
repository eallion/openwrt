# Actions-OpenWrt

Build OpenWrt using GitHub Actions

![Build OpenWrt](https://github.com/eallion/openwrt/workflows/Build%20OpenWrt/badge.svg)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Download

- [Releases](https://github.com/eallion/openwrt/releases/latest/)

This repo only keeps the lastest 5 releases.

### Check sha256sums

Download the [sha256sums](https://github.com/eallion/openwrt/releases/latest/) file.

Make sure the sha256sums file and img file in a same folder.

```shell
sha256sum -c sha256sums --ignore-missing 
```

Windows(git bash)

```shell
sha256sum.exe -c sha256sums --ignore-missing 
```

Make sure its `OK` before upload it.

### Usage

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [Lean's OpenWrt](https://github.com/coolsnowwolf/lede) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

### Download`.config`

On Ubuntu / Debian / WSL ...

```shell
wget -c https://raw.githubusercontent.com/eallion/openwrt/main/.config ~/lede/.config
```

// or 

```shell
git clone https://github.com/eallion/openwrt.git
cd openwrt
cp .config ~/lede/.config # copy config to lede folder.
```
Make on local:
```shell
make -j8 download V=s
make -j$(($(nproc) + 1)) V=s
```
Regenarate `.config`
```shell
rm -rf ./tmp && rm -rf .config
```
```shell
make menuconfig
```
Remake on local or:
Push `.config` to [eallion/openwrt](https://github.com/eallion/openwrt) make on GitHub Actions
```shell
rm ../openwrt/.config
cp .config ../openwrt/
cd ../openwrt
git add .
git commit -m "message"
git push
```
Then you can download firmware at [Releases](https://github.com/eallion/openwrt/releases/latest/) later.

### Customs

##### 1. Add [@fw876/helloworld](https://github.com/fw876/helloworld)

Uncommnet `#src-git` to use
```shell
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default
```

*Option: [@Lienol/openwrt-package](https://github.com/Lienol/openwrt-package)

```
sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
```

##### 2. Default IP

> 192.168.0.1


Change default IP:

```shell
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate
```

##### 3. Image's setting

- GZip images	
- Set 320MB root filesystem partigion size

##### 4. Luci apps

- luci-app-ssr-plus	 
- ……

##### 5. Others
- Enable Nginx for luci and web service
- Enable openssh-sftp-server
- Enable curl and wget
- Enable drill for DDNS
- ~~Enable Docker & Docker Compose~~
- ~~Enable JD daily bonus~~
- ~~Enable ServerChan~~
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
