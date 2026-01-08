#!/bin/bash

# ================= 配置区 =================
REPO="hunter-ji/rime-mate"
BASE_URL="https://github.com/$REPO/releases/latest/download"
TOOL_NAME="rime-mate"

detect_rime_dir() {
    local home="$HOME"
    case "$(uname -s)" in 
    Darwin)
        rime_dir="$home/Library/Rime"
        ;;
    Linux)
        local linux_paths=(
                "$home/.config/ibus/rime"
                "$home/.local/share/fcitx5/rime"
            )
            for p in "${linux_paths[@]}"; do
                if [ -d "$p" ]; then
                    rime_dir="$p"
                    return 0
                fi
            done
            echo "❌ Linux 下未找到 RIME 配置目录，请先安装 IBus-RIME/Fcitx5-RIME"
            exit 1
            ;;
    *)
        echo "❌ 不支持的操作系统: $(uname -s)"
        exit 1
        ;;
    esac
    if [ ! -d "$rime_dir" ]; then
        echo "❌ 未检测到 Rime 配置目录: $rime_dir"
        echo "请先安装对应系统的 Rime 输入法（macOS：鼠须管；Linux：IBus-RIME/Fcitx5-RIME）"
        exit 1
    fi
    echo "✅ 检测到 RIME 配置目录：$rime_dir"
    export RIME_DIR="$rime_dir"
}

echo "⏳ 正在准备环境..."
detect_rime_dir

# 所有文件都放在 Rime 配置目录下
COMMAND_LINK="$RIME_DIR/Rime配置助手.sh"  # 通用
RIME_CONFIG_DIR="$RIME_DIR/rime-mate-config"
BINARY_PATH="$RIME_CONFIG_DIR/$TOOL_NAME"
VERSION_FILE="$RIME_CONFIG_DIR/version"
# =========================================

get_os_arch() {
    local os arch
    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        *) echo "❌ 不支持的系统"; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "❌ 不支持的架构：$(uname -m)"; exit 1 ;;
    esac
    echo "${TOOL_NAME}-${os}-${arch}"
}
FILE_NAME=$(get_os_arch)


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
    echo "⬇️ 正在下载 $FILE_NAME ..."
    mkdir -p "$RIME_CONFIG_DIR"

    curl -L --progress-bar "$BASE_URL/$FILE_NAME" -o "$BINARY_PATH"

    if [ $? -ne 0 ] || [ ! -s "$BINARY_PATH" ]; then
        echo "❌ 下载失败或文件为空，请检查网络连接或服务器状态。"
        rm -f "$BINARY_PATH"
        exit 1
    fi

    echo "$VERSION_TO_WRITE" > "$VERSION_FILE"
    chmod +x "$BINARY_PATH"

    # 设置可执行权限并移除 macOS 隔离属性（避免首次运行时弹出安全警告）
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null
    fi
fi

# --- 步骤B: 在 Rime 配置目录生成“快捷方式” ---

# 只有当配置目录没有这个文件时，才生成
if [ ! -f "$COMMAND_LINK" ]; then
    echo "🖥️ 正在 RIME 配置目录生成快捷方式..."
    
    # 写入跨平台脚本（兼容macOS/Linux）
    cat <<EOF > "$COMMAND_LINK"
#!/bin/bash
set -euo pipefail

# 切换到 RIME 配置目录
TARGET_DIR="$RIME_DIR"
if [ "\$(pwd)" != "\$TARGET_DIR" ]; then
    cd "\$TARGET_DIR" || exit 1
fi

# 运行程序
./rime-mate-config/$TOOL_NAME

# 等待用户按回车退出（Linux终端关闭问题）
echo -e "\\n按回车键退出..."
read -r
EOF

    chmod +x "$COMMAND_LINK"
    
    # 仅macOS移除隔离属性
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -d com.apple.quarantine "$COMMAND_LINK" 2>/dev/null
    fi
    
    echo "✅ 快捷方式已创建：$COMMAND_LINK"
    echo "🛠️ 打开 RIME 配置目录后，运行 './Rime配置助手.sh' 即可启动程序（Linux）/双击运行（macOS）。"
fi

# --- 步骤C: 打开配置文件夹 ---
echo "📂 正在打开 RIME 配置目录..."
case "$(uname -s)" in
    Darwin) open "$RIME_DIR" ;;
    Linux) 
        if command -v xdg-open &> /dev/null; then
            xdg-open "$RIME_DIR"
        else
            echo "⚠️ 未找到 xdg-open，无法自动打开文件夹，手动路径：$RIME_DIR"
        fi
        ;;
esac
