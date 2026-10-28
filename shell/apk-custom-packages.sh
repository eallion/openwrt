#!/bin/bash
# ============= ImmortalWrt 25.12.x 仓库外的第三方插件 apk =============
# ============= 若启用 则打开对应注释 ================================

# 首页和网络向导（依赖于 istore 商店，若集成则连同集成 istore 商店）
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-quickstart-zh-cn"

# Run 安装器（用于快速安装 makeself 打包的 run 文件）
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-run"

# 文件管理器 by github sbwml
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES bash quickfile luci-app-quickfile luci-i18n-quickfile-zh-cn"

# 极光主题和配置 by github eamonxg
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-theme-aurora luci-app-aurora-config luci-i18n-aurora-config-zh-cn"

# 分区扩容 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"

# 流量监控 by timsaya
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES bandix luci-app-bandix luci-i18n-bandix-zh-cn"

# SSR-Plus apk
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-nft-tproxy kmod-nft-socket xray-core naiveproxy luci-app-ssr-plus luci-i18n-ssr-plus-zh-cn"

# PassWall2 apk
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES geoview xray-core sing-box hysteria kmod-nft-socket kmod-nft-tproxy luci-app-passwall2 luci-i18n-passwall2-zh-cn"

# PassWall apk
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES geoview xray-core sing-box hysteria luci-i18n-passwall-zh-cn"

# OpenClash
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash luci-compat kmod-tun kmod-inet-diag kmod-nft-tproxy bash curl ip-full unzip"

# IPTV 流媒体转发服务器 - rtp2httpd by stackia
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-rtp2httpd luci-i18n-rtp2httpd-zh-cn"

# Clashoo by kenzok8（若集成 clashoo 则不能集成 nikki）
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES clashoo luci-app-clashoo luci-i18n-clashoo-zh-cn"

# Lucky 大吉 by gdy666 & sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-lucky lucky luci-i18n-lucky-zh-cn"

# daed
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-daed-zh-cn"

# 定时任务 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-taskplan luci-i18n-taskplan-zh-cn"

# MosDNS
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-mosdns luci-i18n-mosdns-zh-cn"

# Nikki
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-nikki-zh-cn"

# WireGuard
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-proto-wireguard"

# Tailscale
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-tailscale-community luci-i18n-tailscale-community-zh-cn"

# Zerotier
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-zerotier-zh-cn"

# EasyTier
CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-tun luci-app-easytier"

# FRP
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-frpc-zh-cn"
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-frps-zh-cn"

# DDNS-GO
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ddns-go-zh-cn"

# Filebrowser
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-filebrowser-go-zh-cn"
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-filebrowser-zh-cn"

# 网络唤醒
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-wol-zh-cn"

# 酷猫主题 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-theme-kucat"

# 进阶设置 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-advancedplus luci-i18n-advancedplus-zh-cn"

# 网络测速 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-netspeedtest luci-i18n-netspeedtest-zh-cn"

# Turbo ACC 网络加速
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-turboacc"

# 应用过滤
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-appfilter luci-i18n-appfilter-zh-cn"

# 设置向导 by sirpdboy
# CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-netwizard luci-i18n-netwizard-zh-cn"