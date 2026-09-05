# install-service.ps1 - Register the bot as a Windows auto-start task
# Run: powershell -ExecutionPolicy Bypass -File install-service.ps1
#
# Creates a Task Scheduler task, equivalent to the Linux systemd service:
#   - Starts the bot when you log on (or at boot, see -AtStartup)
#   - Restarts it if it stops unexpectedly
#
# Usage:
#   .\install-service.ps1                    # start at logon, restart on failure
#   .\install-service.ps1 -AtStartup         # start at boot (runs as SYSTEM)
#   .\install-service.ps1 -Remove            # unregister the task
#   .\install-service.ps1 -Status            # show task info
#   .\install-service.ps1 -StartNow          # also start it right away
#   .\install-service.ps1 -RestartIntervalSec 30

param(
    [switch]$AtStartup,
    [switch]$Remove,
    [switch]$Status,
    [switch]$StartNow,
    [int]$RestartIntervalSec = 60
)

$ErrorActionPreference = "Stop"
$taskName = "OpenCodeTelegramBot"
$scriptDir = $PSScriptRoot
$runScript = Join-Path $scriptDir "run.ps1"

# Task Scheduler requires the restart interval to be at least 1 minute.
if ($RestartIntervalSec -lt 60) { $RestartIntervalSec = 60 }

function Show-Status {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "Task '$taskName' is NOT registered." -ForegroundColor Yellow
        return
    }
    $state = (Get-ScheduledTaskInfo -TaskName $taskName).LastTaskResult
    Write-Host "Task '$taskName':" -ForegroundColor Cyan
    Write-Host "  State        : $($task.State)"
    Write-Host "  Path         : $($task.Source)"
    Write-Host "  Triggers     : $($task.Triggers.Result -join ', ')"
    Write-Host "  Settings     : RestartCount=$($task.Settings.RestartCount), RestartInterval=$($task.Settings.RestartInterval)"
    Write-Host "  LastRunResult: $state"
}

if ($Status) { Show-Status; exit }

if ($Remove) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Task '$taskName' removed." -ForegroundColor Green
    exit
}

if (-not (Test-Path -LiteralPath $runScript)) {
    Write-Error "run.ps1 not found at $runScript."
}

# Build the task action: run run.ps1 via powershell, hidden window.
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runScript`"" `
    -WorkingDirectory $scriptDir

# Trigger: at boot (SYSTEM) or at logon (current user)
if ($AtStartup) {
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
} else {
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
}

# Settings: auto-restart on failure (equivalent to systemd Restart=on-failure)
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Seconds $RestartIntervalSec) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "OpenCode Telegram Bot - starts automatically and restarts on failure." |
    Out-Null

if ($StartNow) {
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Task '$taskName' registered and started." -ForegroundColor Green
} else {
    Write-Host "Task '$taskName' registered." -ForegroundColor Green
}

Write-Host ""
Show-Status
Write-Host ""
if ($AtStartup) {
    Write-Host "The bot will start on every boot (as SYSTEM)."
} else {
    Write-Host "The bot will start when you log in."
}
Write-Host "To start now:        .\install-service.ps1 -StartNow"
Write-Host "To view status:      .\install-service.ps1 -Status"
Write-Host "To remove:           .\install-service.ps1 -Remove"