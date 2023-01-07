if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


if (!(Get-Module PSWindowsUpdate)) {
    Write-Host "Installing Module PSWindowsUpdate" -ForegroundColor Green -BackgroundColor Black 
    Install-Module -Name PSWindowsUpdate
}

Write-Host "Refreshing Windows Updates" -ForegroundColor Cyan -BackgroundColor Black
Get-WindowsUpdate
Write-Host "Installing Windows Updates" -ForegroundColor Cyan -BackgroundColor Black
Install-WindowsUpdate -AcceptAll
Write-Host "Updating winget apps" -ForegroundColor Cyan -BackgroundColor Black
winget upgrade --all --silent
#winget source reset --force
Write-Host "Updating Windows Store Apps" -ForegroundColor Cyan -BackgroundColor Black
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod | Out-Null
Write-Host "Sleeping 15 seconds." -ForegroundColor Yellow -BackgroundColor Black
Start-Sleep 15
#[void][System.Console]::ReadKey($true)
