#!/bin/bash

# ================= 配置区 =================
REPO="hunter-ji/rime-mate"
BASE_URL="https://github.com/$REPO/releases/latest/download"
TOOL_NAME="rime-mate"

detect_system() {
    case "$(uname -s)" in
        Darwin)
            echo "Darwin"
            ;;
        Linux)
            echo "Linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "Windows"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

detect_rime_dir() {
    home="$HOME"
    system="$(detect_system)"

    case "$system" in
    Darwin)
        rime_dir="$home/Library/Rime"
        ;;
    Linux)
        rime_dir=""
        echo "🔍 正在检查 Linux 下的 Rime 配置路径："
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
            echo "❌ Linux 下未找到 Rime 配置目录，请先安装 IBus-Rime/Fcitx5-Rime"
            exit 1
        fi
        ;;
    Windows)
        rime_dir=""
        echo "🔍 正在检查Windows下的小狼毫(Rime)配置："

        uninstall_reg_path="HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Weasel"
        if reg query "$uninstall_reg_path" >/dev/null 2>&1; then
            echo "   - 小狼毫是否安装? 是"
        else
            echo "   - 小狼毫是否安装? 否"
            echo "❌ Windows 下未检测到小狼毫输入法，请先安装"
            exit 1
        fi

        user_reg_path="HKCU\\Software\\Rime\\Weasel"
        reg_value=$(reg query "$user_reg_path" /v "RimeUserDir" 2>/dev/null \
            | grep -i "RimeUserDir" | awk '{print $NF}')

        if [ -n "$reg_value" ] && [ -d "$reg_value" ]; then
            echo "   - 注册表 RimeUserDir: $reg_value (存在? 是)"
            rime_dir="$reg_value"
        elif [ -n "$reg_value" ]; then
            echo "   - 注册表 RimeUserDir: $reg_value (存在? 否，路径无效)"
            exit 1
        else
            echo "❌ 请使用小狼毫配置工具选择自定义配置目录"
            exit 1
        fi
        ;;
    *)
        echo "❌ 不支持的操作系统"
        exit 1
        ;;
    esac

    echo "✅ 检测到 Rime 配置目录：$rime_dir"
    export RIME_DIR="$rime_dir"
}

echo "⏳ 正在准备环境..."
detect_rime_dir

system="$(detect_system)"
if [ "$system" = "Darwin" ]; then
    COMMAND_LINK="$RIME_DIR/Rime配置助手.command"
elif [ "$system" = "Linux" ]; then
    COMMAND_LINK="$RIME_DIR/Rime配置助手.desktop"
elif [ "$system" = "Windows" ]; then
    COMMAND_LINK="$RIME_DIR/Rime配置助手.bat"
else
    echo "❌ 不支持的操作系统"
    exit 1
fi

RIME_CONFIG_DIR="$RIME_DIR/rime-mate-config"
if [ "$system" = "Windows" ]; then
    BINARY_PATH="$RIME_CONFIG_DIR/$TOOL_NAME.exe"
else
    BINARY_PATH="$RIME_CONFIG_DIR/$TOOL_NAME"
fi

VERSION_FILE="$RIME_CONFIG_DIR/version"
# =========================================

get_os_arch() {
    system="$(detect_system)"
    arch="$(uname -m)"

    case "$system" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        Windows) os="windows" ;;
        *) echo "❌ 不支持的系统"; exit 1 ;;
    esac

    case "$arch" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "❌ 不支持的架构：$arch"; exit 1 ;;
    esac

    if [ "$os" = "windows" ]; then
        echo "${TOOL_NAME}-${os}-${arch}.exe"
    else
        echo "${TOOL_NAME}-${os}-${arch}"
    fi
}
FILE_NAME="$(get_os_arch)"

# --- 步骤A: 版本检测 ---
MISSING_FILES=false
[ ! -f "$COMMAND_LINK" ] && MISSING_FILES=true
[ ! -f "$BINARY_PATH" ] && MISSING_FILES=true
[ ! -f "$VERSION_FILE" ] && MISSING_FILES=true

LATEST_VERSION="$(curl -s "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p')"

NEED_DOWNLOAD=false
if [ "$MISSING_FILES" = true ]; then
    NEED_DOWNLOAD=true
elif [ "$(cat "$VERSION_FILE")" != "$LATEST_VERSION" ]; then
    NEED_DOWNLOAD=true
fi

if [ "$NEED_DOWNLOAD" = true ]; then
    echo "⬇️ 正在下载 $FILE_NAME ..."
    mkdir -p "$RIME_CONFIG_DIR"
    curl -L "$BASE_URL/$FILE_NAME" -o "$BINARY_PATH"

    [ ! -s "$BINARY_PATH" ] && echo "❌ 下载失败" && exit 1

    echo "$LATEST_VERSION" > "$VERSION_FILE"
    chmod +x "$BINARY_PATH"

    if [ "$system" = "Darwin" ]; then
        xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null
    fi
fi

# --- 步骤B: 生成快捷方式 ---
if [ ! -f "$COMMAND_LINK" ]; then
    if [ "$system" = "Darwin" ]; then
        cat <<EOF > "$COMMAND_LINK"
#!/bin/bash
cd "$RIME_DIR"
./rime-mate-config/$TOOL_NAME
EOF
    elif [ "$system" = "Linux" ]; then
        cat <<EOF > "$COMMAND_LINK"
[Desktop Entry]
Type=Application
Name=Rime配置助手
Exec=sh -c 'cd "$RIME_DIR" && ./rime-mate-config/$TOOL_NAME'
Terminal=true
EOF
    elif [ "$system" = "Windows" ]; then
        cat <<EOF > "$COMMAND_LINK"
@echo off
cd /d "%~dp0"
start rime-mate-config\\$TOOL_NAME.exe
EOF
    fi

    chmod +x "$COMMAND_LINK"
fi

# --- 步骤C: 打开配置目录 ---
echo "📂 正在打开 Rime 配置目录..."
case "$system" in
    Darwin) open "$RIME_DIR" ;;
    Linux) command -v xdg-open >/dev/null && xdg-open "$RIME_DIR" ;;
    Windows) explorer "$RIME_DIR" ;;
esac
