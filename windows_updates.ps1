#check if script has already run today
$Path = "HKCU:\WindowsUpdatesLastCheck\"
$WindowsUpdatesLastCheckDate = (Get-Date -Format "yyyy-MM-dd")

if ((Get-ItemProperty $Path -name "WindowsUpdatesLastCheck" -ErrorAction SilentlyContinue | Select-Object -exp "WindowsUpdatesLastCheck") -ne (Get-Date -Format "yyyy-MM-dd") ) {

    # Start PowerShell with elevated priviliges
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process "wt.exe" "powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

    # Check if PSWindowsUpdate is installed
    if (!(Test-Path "$Env:Programfiles\WindowsPowerShell\Modules\PSWindowsUpdate")) {
        Write-Host "Installing Module PSWindowsUpdate" -ForegroundColor Yellow -BackgroundColor Black 
        Install-Module -Name PSWindowsUpdate -Force
    }

    Write-Host "Updating winget apps" -ForegroundColor Cyan -BackgroundColor Black
    winget upgrade --all --silent --include-unknown
    #winget source reset --force
    Write-Host "Updating Windows Store Apps" -ForegroundColor Cyan -BackgroundColor Black
    Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod | Out-Null
    Write-Host "Searching for Windows Updates" -ForegroundColor Cyan -BackgroundColor Black
    Get-WindowsUpdate
    Write-Host "Installing Windows Updates" -ForegroundColor Cyan -BackgroundColor Black
    Install-WindowsUpdate -AcceptAll -Install | Out-Null

    #Create registry file after script has run
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        New-ItemProperty -Name "WindowsUpdatesLastCheck" -Path $Path -Force -PropertyType "String" -Value $WindowsUpdatesLastCheckDate | Out-Null
    }
    else {
        New-ItemProperty -Name "WindowsUpdatesLastCheck" -Path $Path -Force -PropertyType "String" -Value $WindowsUpdatesLastCheckDate | Out-Null | Out-Null
    }
    function keypress_wait {
        param (
            [int]$seconds = 60
        )
        $loops = $seconds * 10
        Write-Host "Press any key to exit. (Window will automatically close in $seconds seconds.)" -ForegroundColor Yellow
        for ($i = 0; $i -le $loops; $i++) {
            if ([Console]::KeyAvailable) { break; }
            Start-Sleep -Milliseconds 100
        }
        if ([Console]::KeyAvailable) { return [Console]::ReadKey($true); }
        else { return $null ; }
    }
    keypress_wait
}

else {}