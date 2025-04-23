[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [System.String] $StorageAccount,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [System.String] $StorageAccountKey
)

#region Store credentials to access the storage account
if (!([System.String]::IsNullOrEmpty($StorageAccount))) {
    cmdkey.exe /add:"$($StorageAccount).privatelink.file.core.windows.net" /user:"localhost\$($StorageAccount)" /pass:"$($StorageAccountKey)"

    # Disable Windows Defender Credential Guard (required for Windows 11 22H2)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /d 0 /t "REG_DWORD" /f | Out-Null
}
#endregion

# FSLogix registry settings - replace or override with policies from GPO or Intune
if (!([System.String]::IsNullOrEmpty($StorageAccount))) {
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "AccessNetworkAsComputerObject" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "DeleteLocalProfileWhenVHDShouldApply" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "FlipFlopProfileDirectoryName" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "IsDynamic" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "PreventLoginWithFailure" /d 0 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "ProfileType" /d 0 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "RoamIdentity" /d 0 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "SizeInMBs" /d 50000 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "VolumeType" /d "vhdx" /t "REG_SZ" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "Enabled" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v "VHDLocations" /d "\\$($StorageAccount).privatelink.file.core.windows.net\profilecontainer" /t "REG_SZ" /f | Out-Null
}

# Add a tag for MDE - update the tag value
$TagValue = "AVD"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection\DeviceTagging" /v "Group" /t "REG_SZ" /d $TagValue /f | Out-Null

# # Enable Entra hybrid join
# $AzureADTenantName = ""
# $AzureADTenantId = ""
# reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD" /v "TenantName" /t "REG_SZ" /d $AzureADTenantName /f | Out-Null
# reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD" /v "TenantId" /t "REG_SZ" /d $AzureADTenantId /f | Out-Null

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
