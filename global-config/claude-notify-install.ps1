$scriptPath = "$env:USERPROFILE\.claude\claude-notify.ps1"
$taskName = 'ClaudeCodeNotify'

$launcherPath = "$env:USERPROFILE\.claude\claude-notify-launcher.vbs"

$action = New-ScheduledTaskAction `
    -Execute 'wscript.exe' `
    -Argument "`"$launcherPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit 0 `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description 'Claude Code notification listener' `
    -Force | Out-Null

Write-Host "Task '$taskName' registered."

# Start it immediately without waiting for next logon
Start-ScheduledTask -TaskName $taskName
Write-Host "Task started. Notifications are active."
