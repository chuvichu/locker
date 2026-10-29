<#
.SYNOPSIS
    Installs and activates the Windows Hosts File Locker as a silent background scheduled task.
#>

# Requires Run as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: Please run this script in an elevated PowerShell session (Run as Administrator)." -ForegroundColor Red
    exit 1
}

$taskName = "WindowsHostsLocker"
$targetDir = "$env:ProgramData\HostsLocker"
$scriptSource = Join-Path $PSScriptRoot "LockHosts.ps1"
$scriptDestination = Join-Path $targetDir "LockHosts.ps1"

Write-Host "=== Installing Windows Hosts Locker ===" -ForegroundColor Cyan

# 1. Create target directory
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# 2. Copy script to ProgramData
Copy-Item -Path $scriptSource -Destination $scriptDestination -Force
Write-Host "[+] Copied LockHosts.ps1 to $targetDir" -ForegroundColor Green

# 3. Configure Scheduled Task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptDestination`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

# 4. Register Scheduled Task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "[+] Registered '$taskName' scheduled task under SYSTEM account." -ForegroundColor Green

# 5. Start task immediately
Start-ScheduledTask -TaskName $taskName
Write-Host "[+] Started task '$taskName'." -ForegroundColor Green

# 6. Verify
Start-Sleep -Seconds 2
$task = Get-ScheduledTask -TaskName $taskName
Write-Host "`nInstallation Complete! Current Status: $($task.State)" -ForegroundColor Cyan
Write-Host "Try cutting, renaming, or deleting 'C:\Windows\System32\drivers\etc\hosts' to verify." -ForegroundColor Yellow
