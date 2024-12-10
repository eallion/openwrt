#!/bin/bash

# ENV
LEDE_PATH="/home/eallion/lede"
TARGET_PATH="/mnt/e/Files/Openwrt/"
LAN_IP="192.168.0.1"

# 检查是否提供了 -f 或 --force 参数
FORCE=false
for arg in "$@"; do
    if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
        FORCE=true
        break
    fi
done

# 进入 LEDE 目录
cd $LEDE_PATH

# 清除编译
make clean

# 更新代码
git fetch
if ! $FORCE; then
    if git diff --quiet HEAD @{u}; then
        echo "No git updates found."
        git_updated=false
    else
        echo "Git updates found."
        git_updated=true
        git pull
    fi
else
    echo "Forcing git pull."
    git_updated=true
    git pull
fi

# 更新软件包
feeds_update_output=$(./scripts/feeds update -a 2>&1)
if ! $FORCE; then
    if [[ "$feeds_update_output" == *"Already up to date."* ]]; then
        echo "No feeds updates found."
        feeds_updated=false
    else
        echo "Feeds updates found."
        feeds_updated=true
    fi
else
    echo "Forcing feeds update."
    feeds_updated=true
fi

# 如果两者都没有更新，则中断脚本
if ! $FORCE && ! $git_updated && ! $feeds_updated; then
    echo "No updates found. Exiting..."
    exit 0
fi

./scripts/feeds install -a

# 修改路由器 IP 地址
sed -i "s/192.168.1.1/$LAN_IP/g" "$LEDE_PATH/package/base-files/files/bin/config_generate"

# 下载依赖的软件包
make download -j32

# 编译固件
time make V=s -j$(nproc)

# 进入源目录
cd "$LEDE_PATH/bin/targets/x86/64/" || { echo "Source directory not found"; exit 1; }

# 定义要复制的文件类型
FILE_TYPES=("*.img" "*.iso" "*.gz" "*.qcow2" "*.vdi" "*.vhdx" "*.vmdk")

# 获取当前时间戳
timestamp=$(date +"%Y%m%d%H%M%S")

# 遍历文件类型并复制文件
for file_type in "${FILE_TYPES[@]}"; do
    # 查找符合条件的文件
    files_to_copy=$(find . -maxdepth 1 -type f -name "$file_type")
    
    # 复制文件到目标目录，并添加时间戳
    if [ -n "$files_to_copy" ]; then
        echo "Copying $file_type files to $TARGET_PATH with timestamp $timestamp"
        for file in $files_to_copy; do
            filename=$(basename "$file")
            new_filename="${timestamp}-${filename}"
            cp --preserve=timestamps "$file" "$TARGET_PATH/$new_filename"
            if [ $? -eq 0 ]; then
                echo "Copied: $new_filename"
                
                # 从 sha256sums 文件中提取对应的 sha256 值
                sha256_value=$(grep --color=none -E "\*$filename" "$LEDE_PATH/bin/targets/x86/64/sha256sums" | awk '{print $1}')
                
                # 生成 .sha256 文件
                if [ -n "$sha256_value" ]; then
                    echo "$sha256_value *$new_filename" > "$TARGET_PATH/$new_filename.sha256"
                    echo "Generated: $new_filename.sha256"
                else
                    echo "Warning: SHA256 value not found for $filename"
                fi
            fi
        done
    fi
done

echo "Sha256 Hash:"
grep --color=none -E "($(IFS='|'; echo "${FILE_TYPES[*]}"))" "$LEDE_PATH/bin/targets/x86/64/sha256sums"
echo "LEDE build successful!"