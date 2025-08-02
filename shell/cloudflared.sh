#!/bin/bash

# 获取最新版本号
latest_version=$(curl -s "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" | grep -oP '"tag_name":\s*"\K[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$latest_version" ]; then
  echo "未能获取最新版本号"
  exit 1
fi

makefile="./packages/cloudflared/Makefile"
config="./packages/cloudflared/files/cloudflared.config"

# 替换 Makefile 中的 PKG_VERSION、PKG_RELEASE、PKG_HASH
sed -i -E "s/^([[:space:]]*PKG_VERSION:=)[0-9]+\.[0-9]+\.[0-9]+/\1$latest_version/" "$makefile"
sed -i -E "s/^([[:space:]]*PKG_RELEASE:=)[0-9]+/\12/" "$makefile"
sed -i -E "s/^([[:space:]]*PKG_HASH:=)[^[:space:]]+/\1skip/" "$makefile"

# 替换 config 中的 option protocol
sed -i -E "s/^([[:space:]]*option protocol ')[^']*'/\1auto'/" "$config"