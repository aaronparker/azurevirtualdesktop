<#
.SYNOPSIS
This script is used to clean up an image by reenabling settings, removing application installers,
and removing logs older than 30 days post image completion.

.DESCRIPTION
The script performs the following actions:
- Removes policies that prevent updates during deployment on Windows 10.
- Removes unnecessary paths in the image, such as "$Env:SystemDrive\Apps" and "$Env:SystemDrive\DeployAgent".
- Clears the Temp directory by removing all items and recreating the directory.
- Deletes logs older than 30 days from the "$Env:SystemRoot\Logs\ImageBuild" directory.
- Disables Windows Update by modifying the registry.

.NOTES
- This script should be run with administrative privileges.
- The script is specifically designed for use in the Nerdio environment.
- Use caution when modifying the registry as it can have unintended consequences.
#>

#description: Reenables settings, removes application installers, and remove logs older than 30 days post image completion
#execution mode: Combined
#tags: Image

$ScriptName = "Clean up image"
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Start: $ScriptName."

# Clean up registry entries
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    # Remove policies
    reg delete "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /f *> $null
}

# Uninstall a list of applications already included in the image or that we don't need
# Microsoft .NET 6.x installs are in the default Windows Server image from the Azure Marketplace
$Targets = @("Microsoft .NET.*Windows Server Hosting",
    "Microsoft .NET Runtime*",
    "Microsoft ASP.NET Core*",
    "Microsoft OLE DB Driver for SQL Server",
    "Microsoft ODBC Driver 17 for SQL Server",
    "Microsoft Windows Desktop Runtime - 8.0.6")
$Targets | ForEach-Object {
    $Target = $_
    Get-InstalledSoftware | Where-Object { $_.Name -match $Target } | ForEach-Object {

        if ($_.UninstallString -match "msiexec") {
            # Match the GUID in the uninstall string
            $GuidMatches = [Regex]::Match($_.UninstallString, "({[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}})")
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/uninstall $($GuidMatches.Value) /quiet /norestart"
                NoNewWindow  = $true
                Wait         = $true
                ErrorAction  = "Continue"
            }
        }
        else {
            # Split the uninstall string to grab the executable path
            $UninstallStrings = $_.UninstallString -split "/"
            $params = @{
                FilePath     = $UninstallStrings[0]
                ArgumentList = "/uninstall /quiet /norestart"
                NoNewWindow  = $true
                Wait         = $true
                ErrorAction  = "Continue"
            }
        }

        # Uninstall the application
        Start-Process @params | Out-Null
    }
}

# Remove paths that we should not need to leave around in the image
if (Test-Path -Path "$Env:SystemDrive\Apps") {
    Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
}
if (Test-Path -Path "$Env:SystemDrive\DeployAgent") {
    Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
}

# Remove items from the Temp directory (note that scripts run as SYSTEM)
Remove-Item -Path $Env:Temp -Recurse -Force -Confirm:$false -ErrorAction "SilentlyContinue"
New-Item -Path $Env:Temp -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

$StopWatch.Stop()
Write-Host "Stop: $ScriptName. Time: $($StopWatch.Elapsed)"
