[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)]([https://github.com/nopantsfriday/restart_steam_client/blob/master/LICENSE](https://github.com/nopantsfriday/windows_updates/blob/main/LICENSE))
<br>Feel free to use, copy, fork, modify, merge, publish or distribute the script and/or parts of the script.
# About
My attempt to automatically install Windows 11 / winget / Windows store apps updates.

If you got suggestions, let me know.

# Installation
- Save the script to any persistent location
- Execute the script

# Description
- Creates a Windows scheduled task which runs the script after the user logs in to Windows
- Starts PowerShell with elevated privileges
- Installs PowerShell module [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate)
- Installs [winget](https://github.com/microsoft/winget-cli) updates
- Installs Windows Store app updates
- Installs Windows updates