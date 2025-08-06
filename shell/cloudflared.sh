#!/bin/bash

# 下载最新版 cloudflared 到 files/usr/bin/cloudflared

[ -d files/usr/bin ] || mkdir -p files/usr/bin

cloudflared_latest_url=$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep browser_download_url | grep cloudflared-linux-amd64 | grep -v fips | grep -v .deb | cut -d '"' -f 4 | head -n 1)
if [ -z "$cloudflared_latest_url" ]; then
  echo "❌ 未获取到 cloudflared 最新下载地址"
  exit 1
fi

wget -q -O files/usr/bin/cloudflared "$cloudflared_latest_url"
chmod +x files/usr/bin/cloudflared
rm -f files/usr/bin/cloudflared.fake
echo "✅ 已下载最新版 cloudflared 到 files/usr/bin/cloudflared"
