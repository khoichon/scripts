# Ensure Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Restoring Family Safety components..." -ForegroundColor Cyan

$tasks = @(
    @{ Name="FamilySafetyMonitor"; Path="\Microsoft\Windows\Shell\" },
    @{ Name="FamilySafetyRefreshTask"; Path="\Microsoft\Windows\Shell\" }
)

# Restore scheduled tasks
$backupTaskState = "$env:ProgramData\FamilySafety_TaskBackup.json"

if (Test-Path $backupTaskState) {
    $state = Get-Content $backupTaskState | ConvertFrom-Json

    foreach ($t in $state) {
        Enable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue

        if ($t.State -eq "Running") {
            Start-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue
        }
    }
}

# Restore cache
$cachePath = "$env:ProgramData\Microsoft\Windows\Parental Controls"
$backupCache = "$env:ProgramData\FamilySafetyCacheBackup"

if (Test-Path $backupCache) {
    New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
    Copy-Item "$backupCache\*" $cachePath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Good job, you'rae back in control." -ForegroundColor Green

Read-Host "Press Enter to exit"
