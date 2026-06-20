# Ensure Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Disabling Family Safety components..." -ForegroundColor Yellow

$tasks = @(
    @{ Name="FamilySafetyMonitor"; Path="\Microsoft\Windows\Shell\" },
    @{ Name="FamilySafetyRefreshTask"; Path="\Microsoft\Windows\Shell\" }
)

# Backup scheduled task state (simple metadata)
$backupTaskState = "$env:ProgramData\FamilySafety_TaskBackup.json"

$state = @()

foreach ($t in $tasks) {
    $task = Get-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue

    if ($task) {
        $state += @{
            Name  = $t.Name
            Path  = $t.Path
            State = $task.State
        }

        Stop-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue
        Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue
    }
}

$state | ConvertTo-Json | Set-Content $backupTaskState -Force

# Stop monitoring process
Stop-Process -Name "WpcMon" -Force -ErrorAction SilentlyContinue

# Backup + clear cache (REVERSIBLE)
$cachePath = "$env:ProgramData\Microsoft\Windows\Parental Controls"
$backupCache = "$env:ProgramData\FamilySafetyCacheBackup"

if (Test-Path $cachePath) {
    New-Item -ItemType Directory -Path $backupCache -Force | Out-Null
    Copy-Item "$cachePath\*" $backupCache -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Output your message
Write-Host "`n'Well, who chose chaos... Well, we have removed EVERY restriction withheld to you. Use the power wisely. Remember, with great power, comes great responsibility.'`n" -ForegroundColor Cyan

# Keep the window open to read the text
Read-Host "Press Enter to exit"
Exit
