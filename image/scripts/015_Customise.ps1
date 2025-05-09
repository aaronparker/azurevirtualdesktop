<#
.SYNOPSIS
Installs Windows Customised Defaults to customize the image and the default profile.

.DESCRIPTION
This script installs Windows Customised Defaults to customize the image and the default profile.
It retrieves the necessary variables from Nerdio Manager or uses default values if no variables are provided. The script then downloads and extracts the installer,
and runs the Install-Defaults.ps1 script with the specified language, time zone, and Appx mode.

.PARAMETER Path
The path where the Windows Customised Defaults will be installed.

.EXAMPLE
.\015_Customise.ps1 -Path "C:\Apps\image-customise"
#>

#description: Installs Windows Customised Defaults to customise the image and the default profile https://stealthpuppy.com/image-customise/
#execution mode: Combined
#tags: Evergreen, Customisation, Language, Image

# Import the shared functions
$ModuleFile = "C:\Apps\Scripts\Functions.psm1"
Import-Module -Name $ModuleFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Install Windows Customised Defaults."

#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\image-customise"
[System.String] $Language = "en-AU"
[System.String] $TimeZone = "AUS Eastern Standard Time"
[System.String] $AppxMode = "Block"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$Installer = Get-EvergreenApp -Name "stealthpuppyWindowsCustomisedDefaults" | Where-Object { $_.Type -eq "zip" } | `
    Select-Object -First 1 | `
    Save-EvergreenApp -CustomPath $Path

# Extract the installer
Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
$InstallFile = Get-ChildItem -Path $Path -Recurse -Include "Install-Defaults.ps1"

# Install the Customised Defaults
Push-Location -Path $InstallFile.Directory
& $InstallFile.FullName -Language $Language -TimeZone $TimeZone -AppxMode $AppxMode
Pop-Location
#endregion
