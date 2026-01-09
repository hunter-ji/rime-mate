# ================= 配置区 =================
$Repo = "hunter-ji/rime-mate"
$BaseUrl = "https://github.com/$Repo/releases/latest/download"
$ToolName = "rime-mate"
# =========================================

Write-Host "⏳ 正在准备环境..."

$uninstallKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Weasel"
if (-not (Test-Path $uninstallKey)) {
    Write-Host "❌ 未检测到小狼毫（Weasel），请先安装后再运行本脚本"
    exit 1
}
Write-Host "✅ 已检测到小狼毫"

$userKey = "HKCU:\Software\Rime\Weasel"
$rimeDir = (Get-ItemProperty -Path $userKey -Name RimeUserDir -ErrorAction SilentlyContinue).RimeUserDir

if (-not $rimeDir -or -not (Test-Path $rimeDir)) {
    Write-Host "❌ 未找到 Rime 用户目录，请在小狼毫配置工具中设置『用户目录』"
    exit 1
}

Write-Host "✅ Rime 配置目录：$rimeDir"

$configDir = Join-Path $rimeDir "rime-mate-config"
$exePath   = Join-Path $configDir "$ToolName.exe"
$versionFile = Join-Path $configDir "version"

$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { throw "不支持的 Windows 架构: $env:PROCESSOR_ARCHITECTURE" }
}

$fileName = "$ToolName-windows-$arch.exe"

$needDownload = $true

try {
    $latest = (Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest").tag_name
    if (Test-Path $versionFile) {
        if ((Get-Content $versionFile) -eq $latest -and (Test-Path $exePath)) {
            $needDownload = $false
        }
    }
} catch {
    Write-Host "⚠️ 无法获取最新版本信息，将强制下载"
}

if ($needDownload) {
    Write-Host "⬇️ 正在下载 $fileName ..."
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null

    $url = "$BaseUrl/$fileName"
    Invoke-WebRequest -Uri $url -OutFile $exePath

    if (-not (Test-Path $exePath)) {
        Write-Host "❌ 下载失败"
        exit 1
    }

    $latest | Out-File -Encoding ascii $versionFile
}

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
