#!/bin/bash

# ================= 配置区 =================
VERSION="v1.0.0"
BASE_URL=""
TOOL_NAME="rime_mate"

# 所有文件都放在 Rime 配置目录下
RIME_DIR="~/Library/Rime"
BINARY_PATH="$RIME_DIR/$TOOL_NAME"
VERSION_FILE="$RIME_DIR/version"
COMMAND_LINK="$RIME_DIR/Rime配置助手.command"
# =========================================

echo "⏳ 正在准备环境..."

# --- 步骤A: 智能下载/更新逻辑 (同上，不再赘述，保持不变) ---
ARCH=$(uname -m)
case $ARCH in
    x86_64) FILE_NAME="${TOOL_NAME}-darwin-amd64" ;;
    arm64)  FILE_NAME="${TOOL_NAME}-darwin-arm64" ;;
    *) echo "❌ 不支持的架构"; exit 1 ;;
esac

NEED_DOWNLOAD=true
if [ -f "$BINARY_PATH" ] && [ -f "$VERSION_FILE" ]; then
    if [ "$(cat "$VERSION_FILE")" == "$VERSION" ]; then
        NEED_DOWNLOAD=false
    fi
fi

if [ "$NEED_DOWNLOAD" = true ]; then
    echo "⬇️ 正在下载最新版本..."
    mkdir -p "$RIME_DIR"
    curl -L --progress-bar "$BASE_URL/$FILE_NAME" -o "$BINARY_PATH"
    echo "$VERSION" > "$VERSION_FILE"
    
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
# 进入 Rime 配置目录
cd "$RIME_DIR"

# 运行程序
./$TOOL_NAME
# 等待用户查看输出
echo ""
echo "按任意键关闭窗口..."
read -n 1 -s
EOF

    # 给这个文件赋予运行权限
    chmod +x "$COMMAND_LINK"
    
    # 移除隔离属性，防止第一次双击弹窗
    xattr -d com.apple.quarantine "$COMMAND_LINK" 2>/dev/null
    
    echo "✅ Rime 配置目录快捷方式已创建！"
fi

# --- 步骤C: 打开配置文件夹 ---
"$COMMAND_LINK"
