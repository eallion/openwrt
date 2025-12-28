#!/bin/bash

# --- 配置信息 ---
COREUTILS_VERSION="9.9"
INSTALL_DIR="$HOME/.local/opt/gnu-coreutils"
SRC_DIR="$HOME/src"
ACTIVATE_SCRIPT="use-gnu.sh"

echo "--- Ubuntu 25.10 GNU Install 环境助手 ---"

# --- 1. 检查本地是否已经安装过 ---
if [ -f "$INSTALL_DIR/bin/install" ]; then
    echo "检测到 GNU Coreutils $COREUTILS_VERSION 已安装在 $INSTALL_DIR"
else
    echo "未检测到 GNU 环境，开始安装流程..."

    # 安装必要的编译环境
    echo "正在安装编译依赖..."
    sudo apt update && sudo apt install -y build-essential wget tar xz-utils

    # 下载并编译 GNU Coreutils
    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR" || exit

    echo "正在从 GNU 官网下载版本 $COREUTILS_VERSION..."
    if ! wget "https://ftp.gnu.org/gnu/coreutils/coreutils-$COREUTILS_VERSION.tar.xz"; then
        echo "错误：下载失败，请检查网络或版本号是否正确。"
        exit 1
    fi

    echo "正在解压..."
    tar xf "coreutils-$COREUTILS_VERSION.tar.xz"
    cd "coreutils-$COREUTILS_VERSION" || exit

    echo "正在配置安装路径..."
    ./configure --prefix="$INSTALL_DIR"

    echo "正在编译 (使用多核并行)..."
    make -j"$(nproc)"

    echo "正在安装到 $INSTALL_DIR..."
    make install

    # 清理源码
    echo "清理临时文件..."
    cd ~ || exit
    rm -rf "$SRC_DIR/coreutils-$COREUTILS_VERSION"
    echo "安装完成！"
fi

# --- 2. 生成/更新项目本地的激活脚本 ---
# 无论是否重新安装，都确保当前目录下有一个可用的 use-gnu.sh
cat <<EOF > "$ACTIVATE_SCRIPT"
# ImmortalWrt/OpenWrt Build Environment Fix
export PATH="$INSTALL_DIR/bin:\$PATH"
echo "✅ GNU 环境已激活: \$(install --version | head -n 1)"
EOF

chmod +x "$ACTIVATE_SCRIPT"

# --- 3. 提示用户如何激活 ---
echo "------------------------------------------------"
echo "配置已就绪！"
echo "请执行以下命令来激活当前终端环境："
echo ""
echo "source $ACTIVATE_SCRIPT"
echo "------------------------------------------------"