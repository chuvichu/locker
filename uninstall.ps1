<#
.SYNOPSIS
    Uninstalls and deactivates the Windows Hosts File Locker.
#>

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: Please run this script in an elevated PowerShell session (Run as Administrator)." -ForegroundColor Red
    exit 1
}

$taskName = "WindowsHostsLocker"
$targetDir = "$env:ProgramData\HostsLocker"

Write-Host "=== Uninstalling Windows Hosts Locker ===" -ForegroundColor Yellow

# 1. Stop and remove scheduled task
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "[+] Removed scheduled task '$taskName'." -ForegroundColor Green
}

# 2. Terminate running background PowerShell instance
$runningProcesses = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%LockHosts.ps1%'" -ErrorAction SilentlyContinue
if ($runningProcesses) {
    $runningProcesses | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force
        Write-Host "[+] Stopped process PID $($_.ProcessId)" -ForegroundColor Green
    }
} else {
    Write-Host "[*] No active locking processes found." -ForegroundColor Gray
}

# 3. Clean up directory
if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "[+] Cleaned up $targetDir" -ForegroundColor Green
}

Write-Host "`nUninstallation Complete! The hosts file is now unlocked." -ForegroundColor Cyan
