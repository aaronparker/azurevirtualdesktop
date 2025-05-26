[CmdletBinding(SupportsShouldProcess = $false)]
param ()

# Add a tag for MDE - update the tag value
$TagValue = "AVD"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection\DeviceTagging" /v "Group" /t "REG_SZ" /d $TagValue /f | Out-Null

# UI fixes
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg" /t "REG_SZ" /d "Tahoma" /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg 2" /t "REG_SZ" /d "Tahoma" /f | Out-Null

# Remove paths not needed in the session host
$Files = @(
    "$Env:SystemDrive\DeprovisioningScript.ps1",
    "$Env:SystemDrive\Users\AgentBootLoaderInstall.txt",
    "$Env:SystemDrive\Users\AgentInstall.txt",
    "$Env:SystemRoot\Temp\*.log",
    "$Env:SystemRoot\Temp\*.tmp",
    "$Env:SystemDrive\DeployAgent\RDAgentBootLoaderInstall\*.msi",
    "$Env:SystemDrive\DeployAgent\RDInfraAgentInstall\*.msi",
    "$Env:SystemDrive\DeployAgent\RDInfraAgentInstall\RDAgent\*.msi",
    "$Env:Public\Desktop\Microsoft Edge.lnk"
)
Remove-Item -Path $Files -Force -ErrorAction "SilentlyContinue"
