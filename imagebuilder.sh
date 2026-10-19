#!/usr/bin/env bash
set -e

# 获取脚本所在项目根目录并切换工作目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 记录 Docker 原始状态
WAS_DOCKER_RUNNING=0
DOCKER_STARTED_BY_SCRIPT=0
IS_DOCKER_ENABLED=0

if systemctl is-enabled --quiet docker 2>/dev/null; then
    IS_DOCKER_ENABLED=1
fi

if systemctl is-active --quiet docker 2>/dev/null; then
    WAS_DOCKER_RUNNING=1
fi

# 退出清理函数：如果原来没有运行或开机未设自启，构建结束后自动停止 Docker 服务（不需要用户选择）
cleanup() {
    local exit_code=$?
    if [ "$DOCKER_STARTED_BY_SCRIPT" -eq 1 ] || [ "$IS_DOCKER_ENABLED" -eq 0 ]; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            echo ""
            echo "=== 正在恢复 Docker 服务状态 ==="
            echo "检测到 Docker 原本未运行或未设置开机自启，正在停止 Docker 服务..."
            sudo systemctl stop docker docker.socket 2>/dev/null || sudo systemctl stop docker 2>/dev/null || true
            echo "Docker 服务已恢复为停止状态。"
        fi
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

echo "=== 1. 检测 Docker 安装状态 ==="
if ! command -v docker >/dev/null 2>&1; then
    echo "未检测到 Docker。"
    read -r -p "是否安装 Docker？[y/N] (默认: N): " install_choice
    install_choice="${install_choice:-N}"
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        echo "正在更新软件包列表并安装 Docker..."
        sudo apt-get update && sudo apt-get install -y docker.io
    else
        echo "已取消安装，脚本退出。"
        exit 1
    fi
else
    echo "Docker 已安装。"
fi

echo "=== 2. 检测 Docker 服务运行状态 ==="
if [ "$WAS_DOCKER_RUNNING" -eq 0 ]; then
    echo "检测到 Docker 服务未在运行。"
    read -r -p "是否现在启动 Docker 服务？[y/N] (默认: N): " start_choice
    start_choice="${start_choice:-N}"
    if [[ "$start_choice" =~ ^[Yy]$ ]]; then
        echo "正在启动 Docker 服务（保持原开机自启状态不变）..."
        sudo systemctl start docker
        DOCKER_STARTED_BY_SCRIPT=1
    else
        echo "用户选择不启动 Docker，构建退出。"
        exit 0
    fi
else
    echo "Docker 服务当前正在运行。"
fi

# 检查当前用户是否有免 sudo 权限访问 docker
if docker info >/dev/null 2>&1; then
    DOCKER_CMD="docker"
elif sudo docker info >/dev/null 2>&1; then
    DOCKER_CMD="sudo docker"
else
    echo "错误：无法连接到 Docker 守护进程，请检查 Docker 状态。"
    exit 1
fi

echo "=== 3. 选择 ImmortalWrt 构建版本 ==="
echo "1) 25.12.2 (默认)"
echo "2) 24.10.6"
echo "3) Custom (自定义版本与配置)"
read -r -p "请选择构建版本 [1/2/3] (默认: 1): " ver_choice
ver_choice="${ver_choice:-1}"

CONFIG_MOUNT=()

case "$ver_choice" in
    1|25.12.2)
        BUILD_VERSION="25.12.2"
        DOCKER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-25.12.2"
        CONFIG_FILE="$PROJECT_ROOT/x86-64/immortalwrt.config"
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "错误：未找到 25.12 配置文件 $CONFIG_FILE"
            exit 1
        fi
        CONFIG_MOUNT=(-v "$CONFIG_FILE:/home/build/immortalwrt/.config")
        ;;
    2|24.10.6)
        BUILD_VERSION="24.10.6"
        DOCKER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-24.10.6"
        CONFIG_FILE="$PROJECT_ROOT/x86-64/immortalwrt-2410.config"
        if [ -f "$CONFIG_FILE" ]; then
            echo "使用 24.10 配置文件: $CONFIG_FILE"
            CONFIG_MOUNT=(-v "$CONFIG_FILE:/home/build/immortalwrt/.config")
        else
            echo "提示：未找到 24.10 配置文件 $CONFIG_FILE"
            read -r -p "是否使用 ImageBuilder 24.10.6 默认配置进行构建？[Y/n] (默认: Y): " fallback_choice
            fallback_choice="${fallback_choice:-Y}"
            if [[ "$fallback_choice" =~ ^[Yy]$ ]]; then
                echo "将使用 ImageBuilder 24.10.6 官方默认配置构建。"
            else
                echo "已取消构建，请准备好 $CONFIG_FILE 后重试。"
                exit 1
            fi
        fi
        ;;
    3|[Cc]ustom)
        BUILD_VERSION="Custom"
        read -r -p "请输入自定义 ImageBuilder 镜像标签 (如 x86-64-openwrt-25.12.1 或完整镜像名, 默认: immortalwrt/imagebuilder:x86-64-openwrt-25.12.2): " custom_img
        custom_img="${custom_img:-immortalwrt/imagebuilder:x86-64-openwrt-25.12.2}"
        if [[ "$custom_img" != *":"* ]]; then
            DOCKER_IMAGE="immortalwrt/imagebuilder:$custom_img"
        else
            DOCKER_IMAGE="$custom_img"
        fi

        read -r -p "请输入配置文件路径 (相对项目路径或绝对路径, 回车留空则构建默认配置): " custom_cfg
        if [ -n "$custom_cfg" ]; then
            if [[ "$custom_cfg" = /* ]]; then
                CUSTOM_CONFIG_FILE="$custom_cfg"
            else
                CUSTOM_CONFIG_FILE="$PROJECT_ROOT/$custom_cfg"
            fi
            if [ -f "$CUSTOM_CONFIG_FILE" ]; then
                echo "使用自定义配置: $CUSTOM_CONFIG_FILE"
                CONFIG_MOUNT=(-v "$CUSTOM_CONFIG_FILE:/home/build/immortalwrt/.config")
            else
                echo "警告：指定的配置文件 $CUSTOM_CONFIG_FILE 不存在，将使用 ImageBuilder 默认配置构建。"
            fi
        else
            echo "未指定配置文件，将使用 ImageBuilder 官方默认配置构建。"
        fi
        ;;
    *)
        echo "无效选项，默认使用 25.12.2"
        BUILD_VERSION="25.12.2"
        DOCKER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-25.12.2"
        CONFIG_FILE="$PROJECT_ROOT/x86-64/immortalwrt.config"
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "错误：未找到 25.12 配置文件 $CONFIG_FILE"
            exit 1
        fi
        CONFIG_MOUNT=(-v "$CONFIG_FILE:/home/build/immortalwrt/.config")
        ;;
esac

echo "已选构建版本: $BUILD_VERSION"
echo "使用 Docker 镜像: $DOCKER_IMAGE"

echo "=== 4. 准备构建环境 ==="
chmod +x "$PROJECT_ROOT/x86-64/build.sh"
if [ -f "$PROJECT_ROOT/shell/apk-prepare-packages.sh" ]; then
    chmod +x "$PROJECT_ROOT/shell/apk-prepare-packages.sh"
fi
if [ -f "$PROJECT_ROOT/shell/prepare-packages.sh" ]; then
    chmod +x "$PROJECT_ROOT/shell/prepare-packages.sh"
fi

mkdir -p "$PROJECT_ROOT/bin"

INTERACTIVE_FLAG="-i"
if [ -t 0 ]; then
    INTERACTIVE_FLAG="-it"
fi

PROFILE="${PROFILE:-4096}"
INCLUDE_DOCKER="${INCLUDE_DOCKER:-no}"
ENABLE_PPPOE="${ENABLE_PPPOE:-no}"
PPPOE_ACCOUNT="${PPPOE_ACCOUNT:-123456}"
PPPOE_PASSWORD="${PPPOE_PASSWORD:-123456}"

echo "固件分区大小: ${PROFILE} MB"
echo "预装 Docker 插件: ${INCLUDE_DOCKER}"
echo "启用 PPPoE 拨号: ${ENABLE_PPPOE}"

echo "=== 5. 调用 Docker ImageBuilder 开始打包 ==="
$DOCKER_CMD run --rm $INTERACTIVE_FLAG \
  --user root \
  -v "$PROJECT_ROOT/bin:/home/build/immortalwrt/bin" \
  -v "$PROJECT_ROOT/files:/home/build/immortalwrt/files" \
  "${CONFIG_MOUNT[@]}" \
  -v "$PROJECT_ROOT/shell:/home/build/immortalwrt/shell" \
  -v "$PROJECT_ROOT/x86-64/build.sh:/home/build/immortalwrt/build.sh" \
  -e BUILD_VERSION="$BUILD_VERSION" \
  -e PROFILE="$PROFILE" \
  -e INCLUDE_DOCKER="$INCLUDE_DOCKER" \
  -e ENABLE_PPPOE="$ENABLE_PPPOE" \
  -e PPPOE_ACCOUNT="$PPPOE_ACCOUNT" \
  -e PPPOE_PASSWORD="$PPPOE_PASSWORD" \
  "$DOCKER_IMAGE" /bin/bash /home/build/immortalwrt/build.sh

echo "=== 6. 构建完成 ==="
OUTPUT_DIR="$PROJECT_ROOT/bin/targets/x86/64"
if [ -d "$OUTPUT_DIR" ]; then
    echo "固件产物目录: $OUTPUT_DIR"
    ls -lh "$OUTPUT_DIR"/*.img.gz 2>/dev/null || true
fi
