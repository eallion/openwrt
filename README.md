# Actions-OpenWrt

Build OpenWrt using GitHub Actions

![Build OpenWrt](https://github.com/eallion/openwrt/workflows/Build%20OpenWrt/badge.svg)

[中文教程 | Read the details in P3TERX's blog (in Chinese)](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

### Download

<https://github.com/eallion/openwrt/releases>

### Usage

- [Fork this Repo](https://github.com/eallion/openwrt) or Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [Lean's OpenWrt](https://github.com/coolsnowwolf/lede) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository, and the build starts automatically.Progress can be viewed on the Actions page.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

### Tips

It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).

Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

### Customs

##### 1. Add lienol's packages
```
sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
```

##### 2. Default IP
```
192.168.0.1
```

##### 3. Image's setting
- GZip images	
- Set 320MB root filesystem partigion size

##### 4. Luci apps
- luci-app-accesscontrol	
- luci-app-adbyby-plus	
- luci-app-arpbind	
- luci-app-baidupcs-web	
- luci-app-ddns	
- luci-app-diskman	
- luci-app-docker	
  - docker-compose
- luci-app-filetransfer	
- luci-app-firewall	
- luci-app-hd-idle	
- [luci-app-jd-dailybonus](https://github.com/jerrykuku/luci-app-jd-dailybonus.git)
  - [node-request](https://github.com/jerrykuku/node-request.git)
- luci-app-minidlna	
- luci-app-netdata	
- luci-app-nlbwmon	
- luci-app-p910nd	
- luci-app-qbittorrent	
- luci-app-ramfree	
- luci-app-samba	
- [luci-app-serverchan](https://github.com/tty228/luci-app-serverchan.git)
- luci-app-sfe	
- luci-app-sqm	
- luci-app-ssr-plus	
- luci-app-unblockmusic	
- luci-app-upnp	
- luci-app-usb-printer	
- luci-app-vlmcsd	
- luci-app-vsftpd	
- luci-app-wireguard	
- luci-app-wol	
- luci-app-xlnetacc
- ……

##### 5. Others
- Enable Nginx for luci and web service
- Enable openssh-sftp-server
- Enable curl and wget
- Enable drill for DDNS

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
