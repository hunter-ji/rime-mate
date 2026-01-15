#!/bin/bash

# ================= 配置区 =================
REPO="hunter-ji/rime-mate"
BASE_URL="https://github.com/$REPO/releases/latest/download"
TOOL_NAME="rime-mate"

# 以下变量仅用于 CI/本地自测
TEST_BASE_URL="${TEST_BASE_URL:-}"      # 覆盖下载源，指向本地 HTTP 服务器
TEST_RIME_DIR="${TEST_RIME_DIR:-}"      # 覆盖 RIME 目录，避免写入真实目录
CI_MODE="${CI_MODE:-0}"                 # CI 模式下跳过交互（open/xattr 等）
VERSION_OVERRIDE="${VERSION_OVERRIDE:-}" # 指定版本号，跳过 GitHub API 请求

detect_rime_dir() {
    if [ -n "$TEST_RIME_DIR" ]; then
        # CI/测试模式：使用临时目录代替真实 RIME 路径
        mkdir -p "$TEST_RIME_DIR"
        echo "🔧 使用测试 RIME 目录：$TEST_RIME_DIR"
        export RIME_DIR="$TEST_RIME_DIR"
        return
    fi

    home="$HOME"
    system="$(uname -s)"

    case "$system" in
    Darwin)
        rime_dir="$home/Library/Rime"
        ;;
    Linux)
        rime_dir=""
        echo "🔍 正在检查Linux下的RIME配置路径："
        if [ -d "$home/.config/ibus/rime" ]; then
            echo "   - $home/.config/ibus/rime (存在? 是)"
            rime_dir="$home/.config/ibus/rime"
        else
            echo "   - $home/.config/ibus/rime (存在? 否)"
        fi
        if [ -z "$rime_dir" ]; then
            if [ -d "$home/.local/share/fcitx5/rime" ]; then
                echo "   - $home/.local/share/fcitx5/rime (存在? 是)"
                rime_dir="$home/.local/share/fcitx5/rime"
            else
                echo "   - $home/.local/share/fcitx5/rime (存在? 否)"
            fi
        fi
        if [ -z "$rime_dir" ]; then
            echo "❌ Linux 下未找到 RIME 配置目录，请先安装 IBus-RIME/Fcitx5-RIME"
            exit 1
        fi
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
system="$(uname -s)"
if [ "$system" = "Darwin" ]; then
    COMMAND_LINK="$RIME_DIR/Rime配置助手.command"
else
    COMMAND_LINK="$RIME_DIR/Rime配置助手.desktop"
fi

RIME_CONFIG_DIR="$RIME_DIR/rime-mate-config"
BINARY_PATH="$RIME_CONFIG_DIR/$TOOL_NAME"
VERSION_FILE="$RIME_CONFIG_DIR/version"
# =========================================

get_os_arch() {
    system="$(uname -s)"
    arch="$(uname -m)"

    case "$system" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        *) echo "❌ 不支持的系统"; exit 1 ;;
    esac

    case "$arch" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "❌ 不支持的架构：$arch"; exit 1 ;;
    esac

    echo "${TOOL_NAME}-${os}-${arch}"
}

FILE_NAME="$(get_os_arch)"
# 仅当设置了测试源时才覆盖下载地址，默认保持生产 URL
EFFECTIVE_BASE_URL="$BASE_URL"
if [ -n "$TEST_BASE_URL" ]; then
    EFFECTIVE_BASE_URL="$TEST_BASE_URL"
fi

# --- 步骤A: 环境检测与版本检查 ---
MISSING_FILES=false
if [ ! -f "$COMMAND_LINK" ] || [ ! -f "$BINARY_PATH" ] || [ ! -f "$VERSION_FILE" ]; then
    MISSING_FILES=true
fi

if [ "$MISSING_FILES" = true ]; then
    echo "✨ 检测到首次安装或文件缺失，正在获取版本信息..."
else
    echo "🔍 环境完整，正在检查更新..."
fi

# 如指定 VERSION_OVERRIDE，则直接使用指定版本；否则向 GitHub 查询最新版本
if [ -n "$VERSION_OVERRIDE" ]; then
    LATEST_VERSION="$VERSION_OVERRIDE"
else
    LATEST_VERSION="$(curl -s --max-time 15 "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p')"

    if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️ 版本信息获取失败，可能是网络或代理问题，将尝试不使用代理获取版本信息"
        LATEST_VERSION="$(curl -s --noproxy "*" --max-time 10 "https://api.github.com/repos/$REPO/releases/latest" \
            | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p')"
    fi
fi

NEED_DOWNLOAD=false
VERSION_TO_WRITE=""

if [ -z "$LATEST_VERSION" ]; then
    if [ "$MISSING_FILES" = true ]; then
        echo "⚠️ 无法获取最新版本信息，且本地文件缺失，将尝试强制安装..."
        NEED_DOWNLOAD=true
        VERSION_TO_WRITE="unknown"
    else
        echo "⚠️ 无法获取最新版本信息，但检测到本地已安装。跳过更新，使用当前版本。"
        NEED_DOWNLOAD=false
    fi
else
    VERSION_TO_WRITE="$LATEST_VERSION"
    if [ "$MISSING_FILES" = true ]; then
        echo "⬇️ 准备下载版本: $LATEST_VERSION"
        NEED_DOWNLOAD=true
    else
        LOCAL_VERSION="$(cat "$VERSION_FILE")"
        if [ "$LOCAL_VERSION" = "$LATEST_VERSION" ]; then
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
    curl -L "$EFFECTIVE_BASE_URL/$FILE_NAME" -o "$BINARY_PATH"

    if [ ! -s "$BINARY_PATH" ]; then
        echo "❌ 下载失败或文件为空，请检查网络连接或服务器状态。"
        rm -f "$BINARY_PATH"
        exit 1
    fi

    echo "$VERSION_TO_WRITE" > "$VERSION_FILE"
    chmod +x "$BINARY_PATH"

    if [ "$CI_MODE" != "1" ] && [ "$(uname -s)" = "Darwin" ]; then
        xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null
    fi
fi

# --- 步骤B: 在 Rime 配置目录生成“快捷方式” ---

if [ ! -f "$COMMAND_LINK" ]; then
    echo "🖥️ 正在 Rime 配置目录生成快捷方式..."

    if [ "$(uname -s)" = "Darwin" ]; then
        cat <<EOF > "$COMMAND_LINK"
#!/bin/bash
TARGET_DIR="$RIME_DIR"
if [ "\$(pwd)" != "\$TARGET_DIR" ]; then
    cd "\$TARGET_DIR"
fi
./rime-mate-config/$TOOL_NAME
echo ""
EOF
    else
        cat <<EOF > "$COMMAND_LINK"
[Desktop Entry]
Type=Application
Name=Rime配置助手
Exec=sh -c 'cd "$RIME_DIR" && ./rime-mate-config/$TOOL_NAME';
Terminal=true
Icon=utilities-terminal
Categories=Utility;
EOF
    fi

    chmod +x "$COMMAND_LINK"

    if [ "$CI_MODE" != "1" ] && [ "$(uname -s)" = "Darwin" ]; then
        xattr -d com.apple.quarantine "$COMMAND_LINK" 2>/dev/null
    fi

    echo "✅ 快捷方式已创建：$COMMAND_LINK"
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "🛠️ 打开 RIME 配置目录后，双击 'Rime配置助手.command' 即可启动配置助手。"
    fi
    if [ "$(uname -s)" = "Linux" ]; then
        echo "🛠️ 打开 RIME 配置目录后，双击 'Rime配置助手.desktop' 即可启动配置助手。"
    fi
fi

# --- 步骤C: 打开配置文件夹 ---
if [ "$CI_MODE" = "1" ]; then
    echo "ℹ️ CI 模式已跳过自动打开 RIME 配置目录"
else
    echo "📂 正在打开 RIME 配置目录..."
    case "$(uname -s)" in
        Darwin) open "$RIME_DIR" ;;
        Linux)
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$RIME_DIR"
            else
                echo "⚠️ 未找到 xdg-open，无法自动打开文件夹，手动路径：$RIME_DIR"
            fi
            ;;
    esac
fi
