#!/bin/bash

# ================= 配置区 =================
REPO="hunter-ji/rime-mate"
BASE_URL="https://github.com/$REPO/releases/latest/download"
TOOL_NAME="rime-mate"

# 所有文件都放在 Rime 配置目录下
RIME_DIR="$HOME/Library/Rime"
COMMAND_LINK="$RIME_DIR/Rime配置助手.command"

RIME_CONFIG_DIR="$RIME_DIR/rime-mate-config"
BINARY_PATH="$RIME_CONFIG_DIR/$TOOL_NAME"
VERSION_FILE="$RIME_CONFIG_DIR/version"
# =========================================

echo "⏳ 正在准备环境..."

# 检查 Rime 配置目录是否存在
if [ ! -d "$RIME_DIR" ]; then
    echo "❌ 未检测到 Rime 配置目录: $RIME_DIR"
    echo "请先安装 Rime 输入法 (鼠须管)，或确认安装位置。"
    exit 1
fi

ARCH=$(uname -m)
case $ARCH in
    x86_64) FILE_NAME="${TOOL_NAME}-amd64" ;;
    arm64)  FILE_NAME="${TOOL_NAME}-arm64" ;;
    *) echo "❌ 不支持的架构"; exit 1 ;;
esac

# --- 步骤A: 环境检测与版本检查 ---
MISSING_FILES=false
# 检查三个关键文件是否存在：快捷方式、二进制文件、版本文件
if [ ! -f "$COMMAND_LINK" ] || [ ! -f "$BINARY_PATH" ] || [ ! -f "$VERSION_FILE" ]; then
    MISSING_FILES=true
fi

if [ "$MISSING_FILES" = true ]; then
    echo "✨ 检测到首次安装或文件缺失，正在获取版本信息..."
else
    echo "🔍 环境完整，正在检查更新..."
fi

# 获取最新版本号
LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

NEED_DOWNLOAD=false
VERSION_TO_WRITE=""

if [ -z "$LATEST_VERSION" ]; then
    echo "⚠️ 无法获取最新版本信息，将尝试强制安装..."
    NEED_DOWNLOAD=true
    VERSION_TO_WRITE="unknown"
else
    VERSION_TO_WRITE="$LATEST_VERSION"
    
    if [ "$MISSING_FILES" = true ]; then
        echo "⬇️ 准备下载版本: $LATEST_VERSION"
        NEED_DOWNLOAD=true
    else
        LOCAL_VERSION=$(cat "$VERSION_FILE")
        if [ "$LOCAL_VERSION" == "$LATEST_VERSION" ]; then
            echo "✅ 当前已是最新版本 ($LOCAL_VERSION)"
            NEED_DOWNLOAD=false
        else
            echo "⬆️ 发现新版本 ($LOCAL_VERSION -> $LATEST_VERSION)"
            NEED_DOWNLOAD=true
        fi
    fi
fi

if [ "$NEED_DOWNLOAD" = true ]; then
    echo "⬇️ 正在下载..."
    
    # 1. 检查一下RIME_CONFIG_DIR文件夹是否存在，如果存在则继续，不存在则创建
    if [ ! -d "$RIME_CONFIG_DIR" ]; then
        mkdir -p "$RIME_CONFIG_DIR"
    fi

    curl -L --progress-bar "$BASE_URL/$FILE_NAME" -o "$BINARY_PATH"

    if [ $? -ne 0 ] || [ ! -s "$BINARY_PATH" ]; then
        echo "❌ 下载失败或文件为空，请检查网络连接或服务器状态。"
        rm -f "$BINARY_PATH"
        exit 1
    fi

    echo "$VERSION_TO_WRITE" > "$VERSION_FILE"
    
    # 设置可执行权限并移除 macOS 隔离属性（避免首次运行时弹出安全警告）
    chmod +x "$BINARY_PATH"
    xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null
fi

# --- 步骤B: 在 Rime 配置目录生成“快捷方式” ---

# 只有当配置目录没有这个文件时，才生成
if [ ! -f "$COMMAND_LINK" ]; then
    echo "🖥️ 正在 Rime 配置目录生成快捷方式..."
    
    # 写入一个简单的脚本到 Rime 配置目录
    cat <<EOF > "$COMMAND_LINK"
#!/bin/bash

# 2. 检测是否就在 RIME_DIR 文件夹中
TARGET_DIR="$RIME_DIR"
if [ "\$(pwd)" != "\$TARGET_DIR" ]; then
    cd "\$TARGET_DIR"
fi

# 运行程序
./rime-mate-config/$TOOL_NAME

echo ""
EOF

    # 给这个文件赋予运行权限
    chmod +x "$COMMAND_LINK"
    
    # 移除隔离属性，防止第一次双击弹窗
    xattr -d com.apple.quarantine "$COMMAND_LINK" 2>/dev/null
    
    echo "✅ Rime 配置目录快捷方式已创建！"
    echo "🛠️ 打开 Rime 配置目录后，双击 'Rime配置助手.command' 即可运行。"
fi

# --- 步骤C: 打开配置文件夹 ---
open "$RIME_DIR"
