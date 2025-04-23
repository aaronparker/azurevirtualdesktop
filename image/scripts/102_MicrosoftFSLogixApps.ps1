<#
.SYNOPSIS
Installs the latest Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor.

.DESCRIPTION
This script installs the latest version of the Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor.
It supports installing a specific version in case of any issues. The script downloads the agent from the specified URI,
unpacks it, and then installs it silently. It also removes any existing shortcuts to FSLogix Apps Online Help.

.PARAMETER Path
The path where the Microsoft FSLogix Apps agent will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\FSLogix".

.EXAMPLE
.\102_MicrosoftFSLogixApps.ps1 -Path "C:\Program Files\FSLogix"

.NOTES
- This script requires the Evergreen module to be installed.
- The script uses secure variables in Nerdio Manager to pass a JSON file with the variables list.
- The script requires an internet connection to download the Microsoft FSLogix Apps agent.
#>

#description: Installs the latest Microsoft FSLogix Apps agent
#execution mode: Combined
#tags: Evergreen, Microsoft, FSLogix

#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\FSLogix"

# Import the shared functions
$ModuleFile = "C:\Apps\Scripts\Functions.psm1"
Import-Module -Name $ModuleFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Install the Microsoft FSLogix Apps agent."

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download and unpack
Import-Module -Name "Evergreen" -Force

$App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force

# Install
foreach ($file in "FSLogixAppsSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        $LogFile = "$Env:SystemRoot\Logs\ImageBuild\$($Installer.Name)$($App.Version).log" -replace " ", ""
        $params = @{
            FilePath     = $Installer.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $true
            ErrorAction  = "Stop"
        }
        Start-Process @params
    }
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
