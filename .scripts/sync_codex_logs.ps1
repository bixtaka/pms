# GitHub Copilot Chat の履歴を pms/codex_logs にコピーする

# VS Code の Copilot Chat フォルダ
$source = Join-Path $env:APPDATA "Code\User\globalStorage\github.copilot-chat"

if (-not (Test-Path $source)) {
    Write-Host "Copilot chat folder not found."
    exit 1
}

# pms/codex_logs の場所
$dest = Join-Path $PSScriptRoot "..\codex_logs"

# なければ作成
if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
}

# 中身をコピー（上書き）
Copy-Item -Path (Join-Path $source "*") -Destination $dest -Recurse -Force

Write-Host "Copilot Chat logs synced."
