#!/bin/bash
# ==============================================================================
# Cloudflared 独立安装模块 (面向 ImmortalWrt 25.12 APK 体系)
# 功能：
# 1. 从当前 ImmortalWrt 25.12 源提取官方 cloudflared-*.apk 作为系统骨架
#    (保留官方 init.d 服务、默认 config、conffiles 与元数据)，同时下载配套的
#    luci-app-cloudflared 及 luci-i18n-cloudflared-zh-cn APK
# 2. 获取 cloudflare/cloudflared 官方最新 Release 的纯静态 cloudflared-linux-amd64
#    二进制替换骨架内 /usr/bin/cloudflared，并使用 apk mkpkg 重打包为
#    cloudflared-<upstream_ver>-r99.apk 注入 /home/build/immortalwrt/packages/
# 3. 更新 /home/build/immortalwrt/packages/packages.adb 索引数据库供 ImageBuilder 构建使用
# ==============================================================================

set -e

echo "=== 正在执行 Cloudflared 模块准备工作 (25.12 APK) ==="

UPSTREAM_REPO="cloudflare/cloudflared"
PKG_DIR="/home/build/immortalwrt/packages"
TMP_DIR="/tmp/cloudflared-build"
DEFAULT_PKG_FEED="https://downloads.immortalwrt.org/releases/25.12.2/packages/x86_64/packages"
DEFAULT_LUCI_FEED="https://downloads.immortalwrt.org/releases/25.12.2/packages/x86_64/luci"

# 定位 apk-tools v3 可执行文件
APK_BIN="$(command -v apk || true)"
if [ -z "$APK_BIN" ] && [ -x /home/build/immortalwrt/staging_dir/host/bin/apk ]; then
    APK_BIN="/home/build/immortalwrt/staging_dir/host/bin/apk"
elif [ -z "$APK_BIN" ] && [ -x ./staging_dir/host/bin/apk ]; then
    APK_BIN="./staging_dir/host/bin/apk"
fi

if [ -z "$APK_BIN" ]; then
    echo "错误：未找到 apk 工具（请在 OpenWrt 25.12 ImageBuilder 容器环境中运行）"
    exit 1
fi

mkdir -p "$PKG_DIR"
rm -rf "$TMP_DIR"
mkdir -p "${TMP_DIR}/extract" "${TMP_DIR}/scripts"

# 1. 解析当前 ImageBuilder 配置的 packages 与 luci 软件源地址（带官方 25.12.2 回退）
PKG_FEED_URL=""
LUCI_FEED_URL=""
if [ -f /home/build/immortalwrt/repositories ]; then
    PKG_FEED_URL=$(grep -v '^[[:space:]]*#' /home/build/immortalwrt/repositories | grep -oE 'https?://[^[:space:]]+/packages/packages\.adb' | head -n1 | sed 's|/packages\.adb$||' || true)
    LUCI_FEED_URL=$(grep -v '^[[:space:]]*#' /home/build/immortalwrt/repositories | grep -oE 'https?://[^[:space:]]+/luci/packages\.adb' | head -n1 | sed 's|/packages\.adb$||' || true)
fi
[ -n "$PKG_FEED_URL" ] || PKG_FEED_URL="$DEFAULT_PKG_FEED"
[ -n "$LUCI_FEED_URL" ] || LUCI_FEED_URL="$DEFAULT_LUCI_FEED"

fetch_pkg_filename() {
    local feed_url="$1"
    local pattern="$2"
    local html=""
    html=$(curl -fsSL "${feed_url}/" 2>/dev/null || true)
    if [ -n "$html" ]; then
        printf '%s\n' "$html" | grep -oE "href=\"(\./)?${pattern}\"" | head -n1 | cut -d '"' -f 2 | sed 's|^\./||' || true
    fi
}

CLOUDFLARED_SKEL_NAME=$(fetch_pkg_filename "$PKG_FEED_URL" 'cloudflared-[0-9][^"]*\.apk')
if [ -z "$CLOUDFLARED_SKEL_NAME" ] && [ "$PKG_FEED_URL" != "$DEFAULT_PKG_FEED" ]; then
    PKG_FEED_URL="$DEFAULT_PKG_FEED"
    CLOUDFLARED_SKEL_NAME=$(fetch_pkg_filename "$PKG_FEED_URL" 'cloudflared-[0-9][^"]*\.apk')
fi

LUCI_APP_NAME=$(fetch_pkg_filename "$LUCI_FEED_URL" 'luci-app-cloudflared-[0-9][^"]*\.apk')
LUCI_I18N_NAME=$(fetch_pkg_filename "$LUCI_FEED_URL" 'luci-i18n-cloudflared-zh-cn-[0-9][^"]*\.apk')
if { [ -z "$LUCI_APP_NAME" ] || [ -z "$LUCI_I18N_NAME" ]; } && [ "$LUCI_FEED_URL" != "$DEFAULT_LUCI_FEED" ]; then
    LUCI_FEED_URL="$DEFAULT_LUCI_FEED"
    LUCI_APP_NAME=$(fetch_pkg_filename "$LUCI_FEED_URL" 'luci-app-cloudflared-[0-9][^"]*\.apk')
    LUCI_I18N_NAME=$(fetch_pkg_filename "$LUCI_FEED_URL" 'luci-i18n-cloudflared-zh-cn-[0-9][^"]*\.apk')
fi

if [ -z "$CLOUDFLARED_SKEL_NAME" ] || [ -z "$LUCI_APP_NAME" ] || [ -z "$LUCI_I18N_NAME" ]; then
    echo "错误：无法从 ImmortalWrt 25.12 软件源检索 cloudflared 相关 APK 包名"
    echo "  PKG_FEED_URL=$PKG_FEED_URL (cloudflared=$CLOUDFLARED_SKEL_NAME)"
    echo "  LUCI_FEED_URL=$LUCI_FEED_URL (luci-app=$LUCI_APP_NAME, i18n=$LUCI_I18N_NAME)"
    exit 1
fi

# 2. 获取 cloudflare/cloudflared 官方最新 Release 版本号与 linux-amd64 下载直链
LATEST_TAG=""
BIN_URL=""

API_RES=$(curl -fsSL "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" 2>/dev/null || true)
if [ -n "$API_RES" ]; then
    LATEST_TAG=$(printf '%s\n' "$API_RES" | grep -m1 '"tag_name"' | cut -d '"' -f 4 || true)
    BIN_URL=$(printf '%s\n' "$API_RES" | grep '"browser_download_url"' | cut -d '"' -f 4 | grep -E '/cloudflared-linux-amd64$' | head -n1 || true)
fi

if [ -z "$LATEST_TAG" ] || [ -z "$BIN_URL" ]; then
    echo "GitHub API 未完整返回，正在尝试通过 Releases 重定向解析..."
    LATEST_EFFECTIVE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${UPSTREAM_REPO}/releases/latest" 2>/dev/null || true)
    LATEST_EFFECTIVE="${LATEST_EFFECTIVE%/}"
    LATEST_TAG="${LATEST_EFFECTIVE##*/}"
    if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "latest" ]; then
        BIN_URL="https://github.com/${UPSTREAM_REPO}/releases/download/${LATEST_TAG}/cloudflared-linux-amd64"
    fi
fi

UPSTREAM_VER="${LATEST_TAG#v}"
if [ -z "$UPSTREAM_VER" ] || ! printf '%s' "$UPSTREAM_VER" | grep -qE '^[0-9]+(\.[0-9]+)*$'; then
    echo "错误：获取到的 Cloudflared 版本号不符合 APK 规范: '$LATEST_TAG'"
    exit 1
fi

if [ -z "$BIN_URL" ]; then
    echo "错误：无法获取 Cloudflared 最新版 linux-amd64 二进制下载地址"
    exit 1
fi

APK_VER="${UPSTREAM_VER}-r99"
SKELETON_APK="${TMP_DIR}/${CLOUDFLARED_SKEL_NAME}"
LUCI_APP_APK="${TMP_DIR}/${LUCI_APP_NAME}"
LUCI_I18N_APK="${TMP_DIR}/${LUCI_I18N_NAME}"
NEW_BIN="${TMP_DIR}/cloudflared-linux-amd64"
OUT_APK="${TMP_DIR}/cloudflared-${APK_VER}.apk"

echo "正在下载 ImmortalWrt 骨架包: ${PKG_FEED_URL}/${CLOUDFLARED_SKEL_NAME}"
curl -fsSL "${PKG_FEED_URL}/${CLOUDFLARED_SKEL_NAME}" -o "$SKELETON_APK"

echo "正在下载 LuCI 与中文语言包 APK:"
echo "  ${LUCI_FEED_URL}/${LUCI_APP_NAME}"
echo "  ${LUCI_FEED_URL}/${LUCI_I18N_NAME}"
curl -fsSL "${LUCI_FEED_URL}/${LUCI_APP_NAME}" -o "$LUCI_APP_APK"
curl -fsSL "${LUCI_FEED_URL}/${LUCI_I18N_NAME}" -o "$LUCI_I18N_APK"

echo "正在下载上游最新版 Cloudflared (${UPSTREAM_VER}): $BIN_URL"
curl -fsSL "$BIN_URL" -o "$NEW_BIN"

ELF_MAGIC=$(head -c 4 "$NEW_BIN" | od -An -tx1 | tr -d ' \n' || true)
if [ ! -s "$NEW_BIN" ] || [ "$ELF_MAGIC" != "7f454c46" ]; then
    echo "错误：下载的 Cloudflared 二进制文件无效或非 ELF 格式"
    exit 1
fi

# 3. 提取官方 APK 骨架并替换二进制，按 OpenWrt 25.12 package-pack.mk 规范重打包
echo "正在解包骨架并将 cloudflared 核心升级为 ${APK_VER}..."
"$APK_BIN" extract --destination "${TMP_DIR}/extract" "$SKELETON_APK"

mkdir -p "${TMP_DIR}/extract/usr/bin"
cp -f "$NEW_BIN" "${TMP_DIR}/extract/usr/bin/cloudflared"
chmod 0755 "${TMP_DIR}/extract/usr/bin/cloudflared"
chown 0:0 "${TMP_DIR}/extract/usr/bin/cloudflared" 2>/dev/null || true

cat > "${TMP_DIR}/scripts/post-install" << 'EOF'
#!/bin/sh
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
export root="${IPKG_INSTROOT}"
export pkgname="cloudflared"
add_group_and_user
default_postinst
EOF

cat > "${TMP_DIR}/scripts/post-upgrade" << 'EOF'
#!/bin/sh
export PKG_UPGRADE=1
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
export root="${IPKG_INSTROOT}"
export pkgname="cloudflared"
add_group_and_user
default_postinst
EOF

cat > "${TMP_DIR}/scripts/pre-deinstall" << 'EOF'
#!/bin/sh
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
export root="${IPKG_INSTROOT}"
export pkgname="cloudflared"
default_prerm
EOF

chmod 0755 "${TMP_DIR}/scripts/post-install" "${TMP_DIR}/scripts/post-upgrade" "${TMP_DIR}/scripts/pre-deinstall"

"$APK_BIN" mkpkg \
    --info "name:cloudflared" \
    --info "version:${APK_VER}" \
    --info "description:Cloudflare Tunnel client" \
    --info "arch:x86_64" \
    --info "license:Apache-2.0" \
    --info "origin:feeds/packages/net/cloudflared" \
    --info "url:https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/" \
    --info "maintainer:Tianling Shen <cnsztl@immortalwrt.org>" \
    --info "depends:libc ca-bundle" \
    --script "post-install:${TMP_DIR}/scripts/post-install" \
    --script "post-upgrade:${TMP_DIR}/scripts/post-upgrade" \
    --script "pre-deinstall:${TMP_DIR}/scripts/pre-deinstall" \
    --files "${TMP_DIR}/extract" \
    --output "$OUT_APK"

if [ ! -s "$OUT_APK" ] || [ ! -s "$LUCI_APP_APK" ] || [ ! -s "$LUCI_I18N_APK" ]; then
    echo "错误：生成的 Cloudflared APK 包文件不完整"
    exit 1
fi

# 清理旧版本同名包并复制到 packages 目录
rm -f "${PKG_DIR}"/cloudflared-[0-9]*.apk "${PKG_DIR}"/luci-app-cloudflared-*.apk "${PKG_DIR}"/luci-i18n-cloudflared-zh-cn-*.apk
cp -v "$OUT_APK" "$LUCI_APP_APK" "$LUCI_I18N_APK" "$PKG_DIR/"
rm -rf "$TMP_DIR"

# 4. 索引处理：若本地签名私钥已存在则更新已签名 packages.adb；否则清理旧索引，
#    交由 ImageBuilder 在 make image (package_index) 阶段生成并签名，防止未签名索引跳过签名校验
if [ -f /home/build/immortalwrt/keys/local-private-key.pem ]; then
    echo "正在为 packages 目录生成/更新已签名 APK 索引数据库 (packages.adb)..."
    (cd "$PKG_DIR" && "$APK_BIN" mkndx \
        --keys-dir /home/build/immortalwrt/keys \
        --sign /home/build/immortalwrt/keys/local-private-key.pem \
        --allow-untrusted \
        -o packages.adb *.apk)
    echo "APK 索引数据库更新完成"
else
    rm -f "${PKG_DIR}/packages.adb"
fi

echo "当前 packages 目录内容清单:"
ls -lah "$PKG_DIR/"

echo "=== Cloudflared 模块准备完成 ==="
