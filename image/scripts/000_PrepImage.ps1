<#
    .SYNOPSIS
    Preps a RDS / AVD image for customization.

    .DESCRIPTION
    This script is used to prepare a RDS (Remote Desktop Services) or AVD (Azure Virtual Desktop) image
    for customization. It performs the following tasks:
    - Sets a policy to prevent Windows updates during deployment.
    - Customizes the Start menu.
    - Enables time zone redirection.
    - Creates and compresses a logs directory.

    .PARAMETER None

    .EXAMPLE
    .\000_PrepImage.ps1
#>

#description: Preps a RDS / AVD image for customization.
#execution mode: Combined
#tags: Image

# Import the shared functions
$ModuleFile = "C:\Apps\Scripts\Functions.psm1"
Import-Module -Name $ModuleFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Start image prep."

# If we're on Windows 11, configure the registry settings
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    Write-LogFile -Message "Configuring Windows 11 settings."

    # Prevent Windows from installing stuff during deployment
    Write-LogFile -Message "Disable Windows updates during deployment."
    reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f *> $null
    reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f *> $null

    # https://www.reddit.com/r/Windows11/comments/17toy5k/prevent_automatic_installation_of_outlook_and_dev/
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate") {
        Write-LogFile -Message "Delete key: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate."
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /f *> $null
    }
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate") {
        Write-LogFile -Message "Delete key: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate."
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f *> $null
    }
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate") {
        Write-LogFile -Message "Delete key: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate."
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /f *> $null
    }
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate") {
        Write-LogFile -Message "Delete key: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate."
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f *> $null
    }

    # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings#allow-windows-updates-to-install-before-initial-user-sign-in
    Write-LogFile -Message "Allow Windows updates to install before initial user sign-in."
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" /v "ScanBeforeInitialLogonAllowed" /d 1 /t "REG_DWORD" /f *> $null
}

# Enable time zone redirection - this can be configure via policy as well
Write-LogFile -Message "Enable time zone redirection."
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableTimeZoneRedirection" /t "REG_DWORD" /d 1 /f *> $null

# Disable remote keyboard layout to keep the locale settings configured in the image
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
Write-LogFile -Message "Disable remote keyboard layout."
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "IgnoreRemoteKeyboardLayout" /d 1 /t "REG_DWORD" /f *> $null

# Create logs directory and compress
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" *> $null
$params = @{
    FilePath     = "$Env:SystemRoot\System32\compact.exe"
    ArgumentList = "/C /S `"$Env:SystemRoot\Logs\ImageBuild`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Write-LogFile -Message "Compress logs directory."
Start-Process @params *> $null
