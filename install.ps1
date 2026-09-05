# install.ps1 - Install OpenCode Telegram Bot on Windows
# Run: powershell -ExecutionPolicy Bypass -File install.ps1
#
# Installs:
#   1. The bot npm package globally
#   2. Copies .env.example -> .env (if not present)
#   3. (Optionally) registers a Task Scheduler task for auto-start on login/boot

$ErrorActionPreference = "Stop"

Write-Host "=== OpenCode Telegram Bot - Windows Installer ===" -ForegroundColor Cyan

# --- 1. Check prerequisites ---
Write-Host "`n[1/3] Checking prerequisites..."
$node = Get-Command node -ErrorAction SilentlyContinue
$npm  = Get-Command npm  -ErrorAction SilentlyContinue

if (-not $node) { Write-Error "Node.js not found. Please install Node.js 18+ from https://nodejs.org and re-run." }
if (-not $npm)  { Write-Error "npm not found. Please install Node.js 18+ from https://nodejs.org and re-run." }

Write-Host "  Node: $((& node --version))"
Write-Host "  npm : $((& npm --version))"

# --- 2. Install or update the bot package ---
Write-Host "`n[2/3] Installing @grinev/opencode-telegram-bot globally..."
& npm install -g "@grinev/opencode-telegram-bot@latest"
if ($LASTEXITCODE -ne 0) { Write-Error "npm install failed." }

$botExe = Get-Command opencode-telegram -ErrorAction SilentlyContinue
if (-not $botExe) {
    Write-Error "Could not find 'opencode-telegram' on PATH after install. Global npm bin may not be on PATH."
}
Write-Host "  Bot command: $($botExe.Source)"

# --- 3. Create .env from template if missing ---
Write-Host "`n[3/3] Setting up .env config..."
$scriptDir = $PSScriptRoot
$envTemplate = Join-Path $scriptDir ".env.example"
$envFile     = Join-Path $scriptDir ".env"

if (-not (Test-Path -LiteralPath $envFile)) {
    Copy-Item -LiteralPath $envTemplate -Destination $envFile
    Write-Host "  Created $envFile from template."
    Write-Host "`n  ! IMPORTANT: Open $envFile and fill in your real values:"
    Write-Host "  !   - TELEGRAM_BOT_TOKEN"
    Write-Host "  !   - TELEGRAM_ALLOWED_USER_ID"
    Write-Host "  !   - OPENCODE_MODEL_ID"
} else {
    Write-Host "  $envFile already exists, skipping."
}

Write-Host "`n=== Install complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit .env with your real values."
Write-Host "  2. Test manually:      .\run.ps1"
Write-Host "  3. Auto-start on boot: .\install-service.ps1"