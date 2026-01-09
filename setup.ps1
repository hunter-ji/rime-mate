# ================= 配置区 =================
$Repo     = "hunter-ji/rime-mate"
$ToolName = "rime-mate"
$BaseUrl  = "https://github.com/$Repo/releases/latest/download"
# =========================================

Write-Host "⏳ 正在准备环境..."

# ---------- 小狼毫 ----------
$uninstallKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Weasel"
if (-not (Test-Path $uninstallKey)) {
    Write-Host "❌ 未检测到小狼毫（Weasel），请先安装后再运行本脚本"
    exit 1
}
Write-Host "✅ 已检测到小狼毫"

# ---------- Rime 目录 ----------
$userKey = "HKCU:\Software\Rime\Weasel"
$rimeDir = (Get-ItemProperty -Path $userKey -Name RimeUserDir -ErrorAction SilentlyContinue).RimeUserDir
if (-not $rimeDir -or -not (Test-Path $rimeDir)) {
    Write-Host "❌ 未找到 Rime 用户目录"
    exit 1
}
Write-Host "✅ Rime 配置目录：$rimeDir"

# ---------- 路径 ----------
$configDir   = Join-Path $rimeDir "rime-mate-config"
$exePath     = Join-Path $configDir "$ToolName.exe"
$versionFile = Join-Path $configDir "version"

# ---------- 架构 ----------
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { Write-Host "❌ 不支持的架构"; exit 1 }
}

$fileName    = "$ToolName-windows-$arch.exe"
$downloadUrl = "$BaseUrl/$fileName"

# ---------- 版本检测 ----------
Write-Host "🔍 正在检测最新版本..."

$latestVersion   = $null
$versionCheckOk  = $false

try {
    $resp = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$Repo/releases/latest" `
        -Headers @{ "User-Agent" = "rime-mate-installer" } `
        -TimeoutSec 10

    if ($resp.tag_name) {
        $latestVersion  = $resp.tag_name
        $versionCheckOk = $true
        Write-Host "✅ 最新版本：$latestVersion"
    }
} catch {}

if (-not $versionCheckOk) {
    Write-Host "⚠️ 无法获取版本信息，将执行强制安装"
}

# ---------- 是否需要安装 ----------
$needInstall = $true

if ($versionCheckOk -and (Test-Path $exePath) -and (Test-Path $versionFile)) {
    $localVersion = Get-Content $versionFile
    if ($localVersion -eq $latestVersion) {
        Write-Host "✅ 已安装最新版本（$localVersion），无需更新"
        $needInstall = $false
    } else {
        Write-Host "⬆️ 已安装版本：$localVersion，将更新至 $latestVersion"
    }
}

if (-not $versionCheckOk) {
    Write-Host "⬇️ 无法判断本地版本，执行强制安装"
}

# ---------- 安装 / 更新 ----------
if ($needInstall) {
    Write-Host "⬇️ 正在下载：$fileName"
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null

    try {
        Start-BitsTransfer `
            -Source $downloadUrl `
            -Destination $exePath `
            -ErrorAction Stop
    } catch {
        Write-Host "❌ 下载失败：当前网络无法访问 GitHub"
        exit 1
    }

    if ($versionCheckOk) {
        $latestVersion | Out-File -Encoding ascii $versionFile
    }

    Write-Host "✅ 安装完成"
}

# ---------- 启动脚本 ----------
$batPath = Join-Path $rimeDir "Rime配置助手.bat"
if (-not (Test-Path $batPath)) {
@"
@echo off
cd /d "%~dp0"
start rime-mate-config\$ToolName.exe
"@ | Out-File -Encoding ascii $batPath
}

Write-Host "📂 正在打开 Rime 配置目录..."
explorer.exe $rimeDir
