# Check for Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch the script as Administrator and close the current one
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Disable the Family Safety scheduled tasks
Stop-ScheduledTask -TaskName "FamilySafetyMonitor" -TaskPath "\Microsoft\Windows\Shell\" -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "FamilySafetyMonitor" -TaskPath "\Microsoft\Windows\Shell\" -ErrorAction SilentlyContinue

Stop-ScheduledTask -TaskName "FamilySafetyRefreshTask" -TaskPath "\Microsoft\Windows\Shell\" -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "FamilySafetyRefreshTask" -TaskPath "\Microsoft\Windows\Shell\" -ErrorAction SilentlyContinue

# Forcefully kill the active monitor process
Stop-Process -Name "WpcMon" -Force -ErrorAction SilentlyContinue

# Wipe the local restrictions cache directory
$cachePath = "$env:ProgramData\Microsoft\Windows\Parental Controls"
if (Test-Path $cachePath) {
    Remove-Item -Path "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Output your message
Write-Host "`n'Well, who chose chaos... Well, we have removed EVERY restriction withheld to you. Use the power wisely. Remember, with great power, comes great responsibility.'`n" -ForegroundColor Cyan

# Keep the window open to read the text
Read-Host "Press Enter to exit"
Exit
