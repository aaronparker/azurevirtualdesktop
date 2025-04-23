<#
.SYNOPSIS
Configures Windows roles, features, and capabilities by enabling or disabling Windows roles and features.

.DESCRIPTION
This script is used to configure Windows roles, features, and capabilities on different versions of Windows,
including Windows Server, Windows 11, and Windows 10. It enables or disables specific Windows roles and features based on the operating system version.
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param ()

# Import the shared functions
$ModuleFile = "C:\Apps\Scripts\Functions.psm1"
Import-Module -Name $ModuleFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Configure Windows roles, features, and capabilities."

#region Script logic
# Add / Remove roles and features (requires reboot at end of deployment)
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        $Features = @("Printing-XPSServices-Features", "AzureArcSetup", "WindowsServerBackupSnapin", "WindowsServerBackup")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-LogFile -Message "Disable-WindowsOptionalFeature: $Feature" -LogLevel 1
            Disable-WindowsOptionalFeature @params
        }

        $Features = @("RDS-RD-Server", "Server-Media-Foundation", "Search-Service", "Remote-Assistance") # "NET-Framework-Core"
        foreach ($Feature in $Features) {
            $params = @{
                Name          = $Feature
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-LogFile -Message "Install-WindowsFeature: $Feature" -LogLevel 1
            Install-WindowsFeature @params
        }

        # Remove other capabilities
        $Capabilities = @("App.StepsRecorder~~~~0.0.1.0",
            "Browser.InternetExplorer~~~~0.0.11.0",
            "Downlevel.NLS.Sorting.Versions.Server~~~~0.0.1.0",
            "MathRecognizer~~~~0.0.1.0",
            "Media.WindowsMediaPlayer~~~~0.0.12.0",
            "Microsoft.Windows.MSPaint~~~~0.0.1.0",
            "Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0",
            "Microsoft.Windows.WordPad~~~~0.0.1.0",
            "XPS.Viewer~~~~0.0.1.0")
        foreach ($Capability in $Capabilities) {
            Write-LogFile -Message "Remove-Capability: $Capability" -LogLevel 1
            & "$Env:SystemRoot\System32\dism.exe" /Online /Remove-Capability /CapabilityName:$Capability /NoRestart /Quiet
        }

        # Remove Azure Arc Setup from running at sign-in
        Write-LogFile -Message "Remove Azure Arc Setup from running at sign-in" -LogLevel 1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AzureArcSetup" /f *> $null

        # Remove unnecessary shortcuts
        Write-LogFile -Message "Remove unnecessary shortcuts" -LogLevel 1
        Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Microsoft Azure services.lnk"

        # Enable services
        foreach ($service in "Audiosrv", "WSearch") {
            try {
                $params = @{
                    Name          = $service
                    StartupType   = "Automatic"
                    WarningAction = "SilentlyContinue"
                    ErrorAction   = "SilentlyContinue"
                }
                Write-LogFile -Message "Enable service: $service" -LogLevel 1
                Set-Service @params
            }
            catch {
                Write-LogFile -Message "Failed to enable service: $service, with: $($_.Exception.Message)" -LogLevel 3
            }
        }
        break
    }
    #endregion

    #region Windows 11
    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*" {
        $Features = @("Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", "MicrosoftWindowsPowerShellV2Root", "MicrosoftWindowsPowerShellV2")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-LogFile -Message "Disable-WindowsOptionalFeature: $Feature" -LogLevel 1
            Disable-WindowsOptionalFeature @params
        }
        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $Features = @("Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", `
                "FaxServicesClientPackage", "WindowsMediaPlayer", "MicrosoftWindowsPowerShellV2Root", `
                "MicrosoftWindowsPowerShellV2")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-LogFile -Message "Disable-WindowsOptionalFeature: $Feature" -LogLevel 1
            Disable-WindowsOptionalFeature @params
        }

        $Features = @("Media.WindowsMediaPlayer~~~~0.0.12.0", "XPS.Viewer~~~~0.0.1.0", `
                "App.Support.QuickAssist~~~~0.0.1.0", "MathRecognizer~~~~0.0.1.0", `
                "Browser.InternetExplorer~~~~0.0.11.0", "Print.Fax.Scan~~~~0.0.1.0")
        foreach ($Feature in $Features) {
            $params = @{
                Name                   = $Feature
                IncludeManagementTools = $true
                WarningAction          = "SilentlyContinue"
                ErrorAction            = "SilentlyContinue"
            }
            Write-LogFile -Message "Uninstall-WindowsFeature: $Feature" -LogLevel 1
            Uninstall-WindowsFeature @params
        }
        break
    }
    #endregion

    default {
        Write-LogFile -Message "Failed to determine OS" -LogLevel 2
    }
}

# https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/uninstall-remote-desktop-connection?tabs=command-prompt
if (Test-Path -Path "$Env:SystemRoot\System32\mstsc.exe") {
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\mstsc.exe"
        ArgumentList = "/uninstall /noPromptBeforeRestart"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Stop"
    }
    Write-LogFile -Message "Uninstall Remote Desktop Connection."
    Start-Process @params *> $null
}
