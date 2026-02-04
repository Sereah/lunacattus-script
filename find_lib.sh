#!/bin/bash

# 1. 尝试获取 AOSP 根目录
# 如果没有 source 过环境，则尝试从当前路径向上寻找 .repo 文件夹来定位
if [ -z "$ANDROID_BUILD_TOP" ]; then
    TOP_DIR=$(pwd)
    while [ "$TOP_DIR" != "/" ] && [ ! -d "$TOP_DIR/.repo" ]; do
        TOP_DIR=$(dirname "$TOP_DIR")
    done
    if [ ! -d "$TOP_DIR/.repo" ]; then
        echo -e "\033[31m错误: 无法定位 AOSP 根目录。请在 AOSP 根目录下执行 'source build/envsetup.sh' 或在源码树内运行此脚本。\033[0m"
        exit 1
    fi
else
    TOP_DIR=$ANDROID_BUILD_TOP
fi

PREBUILT_ROOT="$TOP_DIR/prebuilts/sdk/current"
SEARCH_KEY=$1

if [ -z "$SEARCH_KEY" ]; then
    echo "用法: $0 <关键字>"
    exit 1
fi

echo "--- 正在 AOSP 根目录搜索: $TOP_DIR ---"
echo "--- 目标路径: $PREBUILT_ROOT ---"

# 2. 搜索并处理
# 使用 find 找到所有 Android.bp，然后搜索关键字
FILES=$(find "$PREBUILT_ROOT" -name "Android.bp" -exec grep -l "name: \".*$SEARCH_KEY.*\"" {} +)

if [ -z "$FILES" ]; then
    echo "未找到包含关键字 '$SEARCH_KEY' 的库定义。"
    exit 0
fi

for FILE in $FILES; do
    # 相对路径显示，方便查看
    REL_PATH=${FILE#$TOP_DIR/}
    echo -e "\n\033[32m[文件]: $REL_PATH\033[0m"
    
    # 提取模块定义块
    awk -v key="$SEARCH_KEY" '
        BEGIN { 
            IGNORECASE = 1 
            RED = "\033[31m"
            RESET = "\033[0m"
        }
        # 匹配包含关键字的 name 行
        $0 ~ "name: \".*" key ".*\"" {
            found=1
            print "--------------------------------------"
            # 将 name: "..." 部分替换为红色显示
            line = $0
            gsub(/name: "[^"]+"/, RED "&" RESET, line)
            print line
            next
        }
        found {
            print $0
            # 匹配块结束
            if ($0 ~ /^}/ || $0 ~ /    }/) {
                found=0
                print "--------------------------------------"
            }
        }
    ' "$FILE"
done
