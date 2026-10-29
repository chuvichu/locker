<#
.SYNOPSIS
    Locks the Windows hosts file by holding an exclusive FileShare.Read handle.
.DESCRIPTION
    Opens C:\Windows\System32\drivers\etc\hosts with FileAccess.Read and FileShare.Read.
    Because FileShare.Delete and FileShare.Write are omitted, the Windows kernel strictly
    blocks any attempt to delete, rename, cut, or overwrite the file while this script runs.
#>

[CmdletBinding()]
param(
    [string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
)

# Ensure elevated privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires Administrator privileges."
    exit 1
}

if (-not (Test-Path $HostsPath)) {
    Write-Error "Hosts file not found at: $HostsPath"
    exit 1
}

Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Acquiring exclusive read-lock on: $HostsPath"

try {
    # FileAccess.Read + FileShare.Read
    # Allows Windows DNS Client and browsers to read the file normally,
    # but strictly forbids deletion, renaming, cutting, or writing.
    $fileStream = [System.IO.File]::Open(
        $HostsPath,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )

    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Lock acquired successfully. System deletion and modification blocked."

    # Keep stream open indefinitely
    while ($true) {
        Start-Sleep -Seconds 3600
    }
}
catch {
    Write-Error "Failed to lock hosts file: $($_.Exception.Message)"
    exit 1
}
finally {
    if ($null -ne $fileStream) {
        Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Releasing lock handle."
        $fileStream.Close()
        $fileStream.Dispose()
    }
}
