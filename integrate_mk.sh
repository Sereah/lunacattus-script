#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOSP_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

TARGET_MK="$AOSP_ROOT/device/google/coral/device-flame.mk"
INCLUDE_LINE="-include vendor/lunacattus/mk/pre_install.mk"

echo "Checking target file: $TARGET_MK"

if [ ! -f "$TARGET_MK" ]; then
    echo "Error: Target file not found!"
    exit 1
fi

# 1. 强制删除所有匹配的行（不管它在哪，有多少行）
# 使用 | 作为定界符，确保路径中的 / 不冲突
sed -i "\|$INCLUDE_LINE|d" "$TARGET_MK"

# 2. 删除文件末尾所有的空白行（回车、空格、制表符）
# 使用 perl 是处理文件末尾多行空白最简单、跨平台最稳健的方法
perl -i -pe 'BEGIN{undef $/;} s/\s+\z//' "$TARGET_MK"

# 3. 追加内容：两个换行 + 目标行 + 一个换行
# 这样能保证与上方逻辑块之间始终有一个空行隔开
printf "\n\n%s\n" "$INCLUDE_LINE" >> "$TARGET_MK"

if [ $? -eq 0 ]; then
    echo "Success: Cleanup complete and integrated cleanly."
else
    echo "Error: Failed to write."
    exit 1
fi
