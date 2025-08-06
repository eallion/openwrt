#!/bin/bash

# 下载最新版 DDNS-GO 到 files/usr/bin/ddns-go

[ -d files/usr/bin ] || mkdir -p files/usr/bin

ddns_go_latest_url=$(curl -s https://api.github.com/repos/jeessy2/ddns-go/releases/latest | grep browser_download_url | grep linux_x86_64 | cut -d '"' -f 4 | head -n 1)
if [ -z "$ddns_go_latest_url" ]; then
  echo "❌ 未获取到 DDNS-GO 最新下载地址"
  exit 1
fi

wget -q -O files/usr/bin/ddns-go "$ddns_go_latest_url"
chmod +x files/usr/bin/ddns-go
rm -f files/usr/bin/ddns-go.fake
echo "✅ 已下载最新版 DDNS-GO 到 files/usr/bin/ddns-go"
