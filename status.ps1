<#
.SYNOPSIS
    Inspects whether the hosts file lock is currently active and healthy.
#>

$taskName = "WindowsHostsLocker"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

Write-Host "=== Windows Hosts Locker Status ===" -ForegroundColor Cyan

# 1. Scheduled Task Status
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "[+] Scheduled Task: INSTALLED (State: $($task.State))" -ForegroundColor Green
} else {
    Write-Host "[-] Scheduled Task: NOT INSTALLED" -ForegroundColor Yellow
}

# 2. Active Locking Process
$proc = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%LockHosts.ps1%'" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[+] Active Locking Process: RUNNING (PID: $($proc.ProcessId))" -ForegroundColor Green
} else {
    Write-Host "[-] Active Locking Process: NOT RUNNING" -ForegroundColor Red
}

# 3. Lock Test (Attempt to open for write/delete share)
try {
    $testStream = [System.IO.File]::Open($hostsPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    $testStream.Close()
    Write-Host "[-] Lock Test: FAILED (File can currently be modified or deleted!)" -ForegroundColor Red
}
catch {
    Write-Host "[+] Lock Test: SUCCESS (File is actively locked by Windows kernel!)" -ForegroundColor Green
}
