# run.ps1 - Run the bot in the foreground (for testing)
# Usage: powershell -ExecutionPolicy Bypass -File run.ps1
#
# Loads .env from this folder and starts the bot.
# Ctrl+C to stop.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$envFile   = Join-Path $scriptDir ".env"

if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Error ".env not found at $envFile. Run install.ps1 first."
}

# Load environment variables from .env
Write-Host "Loading configuration from $envFile"
Get-Content -LiteralPath $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $eq = $line.IndexOf("=")
        if ($eq -gt 0) {
            $key = $line.Substring(0, $eq).Trim()
            $val = $line.Substring($eq + 1).Trim()
            # Strip surrounding quotes if present
            if ($val.Length -ge 2 -and $val[0] -eq '"' -and $val[-1] -eq '"') {
                $val = $val.Substring(1, $val.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($key, $val, "Process")
        }
    }
}

Write-Host "Starting OpenCode Telegram Bot (Ctrl+C to stop)..."
# The bot uses OPENCODE_TELEGRAM_HOME to find state/settings
$env:OPENCODE_TELEGRAM_HOME = $scriptDir

& opencode-telegram start
exit $LASTEXITCODE