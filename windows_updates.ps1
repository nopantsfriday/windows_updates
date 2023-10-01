# Define the path to the script file for the scheduled task
function Get-ScriptAbsolutePath {
    $ScriptPath = $PSScriptRoot

    if (-not $ScriptPath) {
        # If $PSScriptRoot is not available, fallback to using the script's location
        $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }

    $ScriptFileName = [System.IO.Path]::GetFileName($PSCommandPath)
    $ScriptAbsolutePath = Join-Path -Path $ScriptPath -ChildPath $ScriptFileName
    return $ScriptAbsolutePath
}

# Call the function to get the absolute path of the current script
$CurrentScriptPath = Get-ScriptAbsolutePath


# Define the registry path to store the last update check date
$RegistryPath = "HKCU:\WindowsUpdatesLastCheck\"

# Get the current date in the yyyy-MM-dd format
$WindowsUpdatesLastCheckDate = Get-Date -Format "yyyy-MM-dd"

# Define custom console colors
$consoleColors = @{
    Green   = [System.ConsoleColor]::Green
    Blue    = [System.ConsoleColor]::Blue
    Magenta = [System.ConsoleColor]::Magenta
    Cyan    = [System.ConsoleColor]::Cyan
    Red     = [System.ConsoleColor]::Red
}

function Update-Progress {
    param (
        [string]$Status,
        [int]$PercentComplete,
        [System.ConsoleColor]$TextColor = [System.ConsoleColor]::White,
        [System.ConsoleColor]$BackgroundColor = [System.ConsoleColor]::Black
    )

    $progressParams.Status = $Status
    $progressParams.PercentComplete = $PercentComplete
    Write-Progress @progressParams

    # Set console colors
    $PrevTextColor = $Host.UI.RawUI.ForegroundColor
    $PrevBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $TextColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor

    Write-Host $Status

    # Reset console colors to previous values
    $Host.UI.RawUI.ForegroundColor = $PrevTextColor
    $Host.UI.RawUI.BackgroundColor = $PrevBackgroundColor
}


# Check if the script has not run today
if ((Get-ItemProperty $RegistryPath -Name "WindowsUpdatesLastCheck" -ErrorAction SilentlyContinue).WindowsUpdatesLastCheck -ne $WindowsUpdatesLastCheckDate) {
    
    # Check if the script is running with elevated privileges (as Administrator). If not running as Administrator, start a new elevated Windows Terminal instance and exit the current one.
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
        Start-Process "wt.exe" "powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
    }

    Write-Host "The absolute path of the current script is: $CurrentScriptPath" -ForegroundColor Yellow -BackgroundColor Black

    # Create empty space for progress bar
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    
    # Create a progress bar for the entire script
    $host.privatedata.ProgressForegroundColor = "yellow";
    $host.privatedata.ProgressBackgroundColor = "darkgray";
    $progressParams = @{
        Activity        = "Updating Windows"
        Status          = "Initializing..."
        PercentComplete = 0
    }

    Write-Progress @progressParams

    Update-Progress -Status "Checking for scheduled task..." -PercentComplete 10

    # Create a scheduled task to run the script at user logon if it doesn't already exist
    if (-not (Get-ScheduledTask -TaskName "windows_updates" -ErrorAction SilentlyContinue)) {
        $trigger = New-ScheduledTaskTrigger -AtLogon
        $User = "$env:COMPUTERNAME\$env:USERNAME"
        $PS = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File `"$CurrentScriptPath`""

        # Attempt to register the task
        $registeredTask = Register-ScheduledTask -TaskName "windows_updates" -Trigger $trigger -User $User -Action $PS -RunLevel Highest -ErrorAction SilentlyContinue

    }
    if (Get-ScheduledTask -TaskName "windows_updates") {
        Update-Progress -Status "Scheduled task 'windows_updates' created successfully." -PercentComplete 30 -TextColor Green
    }
    else {
        Update-Progress -Status "Failed to create the scheduled task 'windows_updates'." -PercentComplete 30 -TextColor Red
    }

    Update-Progress -Status "Checking for PSWindowsUpdate module..." -PercentComplete 40

    # Check if PSWindowsUpdate module is installed; if not, install it
    $PSWindowsUpdateInstalled = (Test-Path "$Env:ProgramFiles\WindowsPowerShell\Modules\PSWindowsUpdate")
    if (-not ($PSWindowsUpdateInstalled)) {
        Install-Module -Name PSWindowsUpdate -Force

    }

    if ($PSWindowsUpdateInstalled) {
        Update-Progress -Status "Module PSWindowsUpdate installed." -PercentComplete 50 -TextColor Green
    }
    else {
        Update-Progress -Status "Failed to install Module PSWindowsUpdate." -PercentComplete 50 -TextColor Red
    }


    Update-Progress -Status "Updating winget apps..." -PercentComplete 60
    
    # Update winget apps
    winget upgrade --all --silent --include-unknown
    # Uncomment the following line to reset the winget source if needed
    # winget source reset --force
    Write-Host "Winget apps updated." -ForegroundColor $consoleColors.Green

    Update-Progress -Status "Updating Windows Store Apps..." -PercentComplete 70

    # Update Windows Store Apps
    Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod | Out-Null
    Write-Host "Windows Store Apps updated." -ForegroundColor $consoleColors.Blue

    Update-Progress -Status "Searching and installing Windows Updates..." -PercentComplete 80
    
    # Search for and install Windows Updates
    Get-WindowsUpdate -AcceptAll -Install
    Write-Host "Windows Updates installed." -ForegroundColor $consoleColors.Magenta

    Update-Progress -Status "Updating registry..." -PercentComplete 90

    # Create or update the registry value with the current date
    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    Set-ItemProperty -Path $RegistryPath -Name "WindowsUpdatesLastCheck" -Type String -Value $WindowsUpdatesLastCheckDate | Out-Null | Out-Null
    Write-Host "Registry updated." -ForegroundColor $consoleColors.Cyan

    Update-Progress -Status "Script completed." -PercentComplete 100
}

# Wait for a keypress to exit (window will automatically close in 60 seconds)
function keypress_wait {
    param (
        [int]$seconds = 20
    )
    $timeout = [System.Diagnostics.Stopwatch]::StartNew()
    $timeoutInMilliseconds = $seconds * 1000
    $message = "Press any key to exit. (Window will automatically close in $seconds seconds.)"
    Write-Host $message -ForegroundColor Yellow

    while ($true) {
        if ([Console]::KeyAvailable) {
            return [Console]::ReadKey($true)
        }

        if ($timeout.ElapsedMilliseconds -ge $timeoutInMilliseconds) {
            return $null
        }

        Start-Sleep -Milliseconds 100
    }
}
keypress_wait
