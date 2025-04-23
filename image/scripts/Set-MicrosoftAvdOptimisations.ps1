<#
    .NOTES
    https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/WindowsOptimization.ps1
#>
[CmdletBinding()]
param ()

begin {
  $ScriptName = "Microsoft AVD Optimisations"
  $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  Write-Host "Start: $ScriptName."
}

process {
  #region Disable Scheduled Tasks
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/ScheduledTasks.json
  $Tasks = "AnalyzeSystem", "Cellular", "Consolidator", "Diagnostics", "FamilySafetyMonitor", "FamilySafetyRefreshTask", `
    "MapsToastTask", "*Compatibility*", "Microsoft-Windows-DiskDiagnosticDataCollector", "NotificationTask", "ProcessMemoryDiagnosticEvents", `
    "Proxy", "QueueReporting", "RecommendedTroubleshootingScanner", "RegIdleBackup", "RunFullMemoryDiagnostic", "ScheduledDefrag", `
    "SpeechModelDownloadTask", "Sqm-Tasks", "SR", "StartComponentCleanup", "WindowsActionDialog", "WinSAT", "XblGameSaveTask", `
    "UsbCeip", "VerifyWinRE", "Restore"
  $Tasks | ForEach-Object { Get-ScheduledTask -TaskName $_ | Disable-ScheduledTask -ErrorAction SilentlyContinue }
  #endregion

  #region Customize Default User Profile
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/DefaultUserSettings.json
  #endregion

  #region Disable Windows Traces
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/Autologgers.Json
  $Traces = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Cellcore\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WDIContextLog\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WiFiDriverIHVSession\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WiFiSession\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReFSLog\", `
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Mellanox-Kernel\"
  $Traces | ForEach-Object { New-ItemProperty -Path ("{0}" -f $_) -Name "Start" -PropertyType "DWORD" -Value 0 -Force -ErrorAction "Stop" }
  #endregion

  #region Disable Services
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/Services.json
  $Services = "autotimesvc", "BcastDVRUserService", "DiagSvc", "DiagTrack", "DPS", "DusmSvc", "icssvc", "lfsvc", "MapsBroker", `
    "MessagingService", "RmSvc", "SEMgrSvc", "SmsRouter", "SysMain", "WdiSystemHost", "WerSvc", "XblAuthManager", "XblGameSave", `
    "XboxGipSvc", "XboxNetApiSvc"
  $Services | ForEach-Object { Set-Service -Name $_ -StartupType "Disabled" }
  #endregion

  #region Network Optimization
  # "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/LanManWorkstation.json"
  $Keys = @"
[
  {
    "Name": "DisableBandwidthThrottling",
    "PropertyType": "DWORD",
    "PropertyValue": 1
  },
  {
    "Name": "FileInfoCacheEntriesMax",
    "PropertyType": "DWORD",
    "PropertyValue": 1024
  },
  {
    "Name": "DirectoryCacheEntriesMax",
    "PropertyType": "DWORD",
    "PropertyValue": 1024
  },
  {
    "Name": "FileNotFoundCacheEntriesMax",
    "PropertyType": "DWORD",
    "PropertyValue": 1024
  },
  {
    "Name": "DormantFileLimit",
    "PropertyType": "DWORD",
    "PropertyValue": 256
  }
]
"@ | ConvertFrom-Json
  foreach ($Key in $Keys) {
    $Path = "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\"
    if (Get-ItemProperty -Path $Path -Name $Key.Name -ErrorAction "SilentlyContinue") {
      Set-ItemProperty -Path $Path -Name $Key.Name -Value $Key.PropertyValue -Force
    }
    else {
      New-ItemProperty -Path $Path -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force
    }
  }
  # NIC Advanced Properties performance settings for network biased environments
  Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB -NoRestart
  #endregion

  #region Local Group Policy Settings
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/PolicyRegSettings.json
  $Settings = @"
[
  {
    "RegItemPath": "HKLM:\\Software\\Policies\\Microsoft\\Dsh",
    "RegItemValueName": "AllowNewsAndInterests",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\Software\\Policies\\Microsoft\\Windows\\Windows Feeds",
    "RegItemValueName": "EnableFeeds",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search",
    "RegItemValueName": "EnableDynamicContentInWSB",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "AllowOnlineTips",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Personalization",
    "RegItemValueName": "LockScreenImage",
    "RegItemValueType": "String",
    "RegItemValue": "C:\\Windows\\web\\screen\\img105.jpg",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Personalization",
    "RegItemValueName": "LockScreenOverlaysDisabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\InputPersonalization",
    "RegItemValueName": "RestrictImplicitInkCollection",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\InputPersonalization",
    "RegItemValueName": "RestrictImplicitTextCollection",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\BITS",
    "RegItemValueName": "DisableBranchCache",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\BITS",
    "RegItemValueName": "DisablePeerCachingClient",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\BITS",
    "RegItemValueName": "DisablePeerCachingServer",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\BITS",
    "RegItemValueName": "EnablePeerCaching",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\PeerDist\\Service",
    "RegItemValueName": "Enable",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "DisableLockScreenAppNotifications",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "DontEnumerateConnectedUsers",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "EnableFontProviders",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\HotspotAuthentication",
    "RegItemValueName": "Enabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Peernet",
    "RegItemValueName": "Disabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\NetCache",
    "RegItemValueName": "Enabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\TCPIP\\v6Transition",
    "RegItemValueName": "Teredo_State",
    "RegItemValueType": "String",
    "RegItemValue": "Disabled",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\WcmSvc\\wifinetworkmanager\\config",
    "RegItemValueName": "AutoConnectAllowedOEM",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WwanSvc\\CellularDataAccess",
    "RegItemValueName": "LetAppsAccessCellularData",
    "RegItemValueType": "DWord",
    "RegItemValue": "2",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WwanSvc\\CellularDataAccess",
    "RegItemValueName": "LetAppsAccessCellularData_ForceAllowTheseApps",
    "RegItemValueType": "MultiString",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WwanSvc\\CellularDataAccess",
    "RegItemValueName": "LetAppsAccessCellularData_ForceDenyTheseApps",
    "RegItemValueType": "MultiString",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WwanSvc\\CellularDataAccess",
    "RegItemValueName": "LetAppsAccessCellularData_UserInControlOfTheseApps",
    "RegItemValueType": "MultiString",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\PushNotifications",
    "RegItemValueName": "NoCloudApplicationNotification",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeviceInstall\\Settings",
    "RegItemValueName": "DisableSystemRestore",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeviceInstall\\Settings",
    "RegItemValueName": "DisableBalloonTips",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeviceInstall\\Settings",
    "RegItemValueName": "DisableSendRequestAdditionalSoftwareToWER",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeviceInstall\\Settings",
    "RegItemValueName": "DisableSendGenericDriverNotFoundToWER",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Device Metadata",
    "RegItemValueName": "PreventDeviceMetadataFromNetwork",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SYSTEM\\CurrentControlSet\\Policies",
    "RegItemValueName": "NtfsDisable8dot3NameCreation",
    "RegItemValueType": "DWord",
    "RegItemValue": "3",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "EnableCdp",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\HandwritingErrorReports",
    "RegItemValueName": "PreventHandwritingErrorReports",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\SQMClient\\Windows",
    "RegItemValueName": "CEIPEnable",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DriverSearching",
    "RegItemValueName": "DontSearchWindowsUpdate",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\EventViewer",
    "RegItemValueName": "MicrosoftEventVwrDisableLinks",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\PCHealth\\HelpSvc",
    "RegItemValueName": "Headlines",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\PCHealth\\HelpSvc",
    "RegItemValueName": "MicrosoftKBSearch",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Internet Connection Wizard",
    "RegItemValueName": "ExitOnMSICW",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Registration Wizard Control",
    "RegItemValueName": "NoRegistration",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\SearchCompanion",
    "RegItemValueName": "DisableContentFileUpdates",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoInternetOpenWith",
    "RegItemValueType": "DWord",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoWebServices",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoOnlinePrintsWizard",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoPublishingWizard",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\TabletPC",
    "RegItemValueName": "PreventHandwritingDataSharing",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System",
    "RegItemValueName": "EnableFirstLogonAnimation",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "EnumerateLocalUsers",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
    "RegItemValueName": "DisableAcrylicBackgroundOnLogon",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoWelcomeScreen",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Power\\PowerSettings\\309dce9b-bef4-4119-9921-a851fb12f0f4",
    "RegItemValueName": "ACSettingIndex",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WinRE",
    "RegItemValueName": "DisableSetup",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\StorageHealth",
    "RegItemValueName": "AllowDiskHealthModelUpdates",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\SystemRestore",
    "RegItemValueName": "DisableSR",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\ScheduledDiagnostics",
    "RegItemValueName": "EnabledExecution",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\ScriptedDiagnostics",
    "RegItemValueName": "EnableDiagnostics",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{67144949-5132-4859-8036-a737b43825d8}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{eb73b633-3f4e-4ba0-8f60-8f3c6f53168f}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{9c5a40da-b965-4fc3-8781-88dd50a6299d}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{3af8b24a-c441-4fa4-8c5c-bed591bfa867}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{2698178D-FDAD-40AE-9D3C-1371703ADC5B}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{ffc42108-4920-4acf-a4fc-8abdcc68ada4}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WDI\\{a7a5847a-7511-4e4e-90b1-45ad2a002f51}",
    "RegItemValueName": "ScenarioExecutionEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AdvertisingInfo",
    "RegItemValueName": "DisabledByGroupPolicy",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AppCompat",
    "RegItemValueName": "DisableInventory",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoDriveTypeAutoRun",
    "RegItemValueType": "DWord",
    "RegItemValue": "255",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoAutoRun",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "DisableSoftLanding",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "DisableWindowsConsumerFeatures",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\PreviewBuilds",
    "RegItemValueName": "AllowBuildPreview",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
    "RegItemValueName": "DoNotShowFeedbackNotifications",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
    "RegItemValueName": "MicrosoftEdgeDataOptIn",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeliveryOptimization",
    "RegItemValueName": "DODownloadMode",
    "RegItemValueType": "DWord",
    "RegItemValue": "99",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DWM",
    "RegItemValueName": "DisableAccentGradient",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DWM",
    "RegItemValueName": "DisallowAnimations",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\EdgeUI",
    "RegItemValueName": "AllowEdgeSwipe",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\EdgeUI",
    "RegItemValueName": "DisableHelpSticker",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "NoNewAppAlert",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\FileHistory",
    "RegItemValueName": "Disabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\HomeGroup",
    "RegItemValueName": "DisableHomeGroup",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer",
    "RegItemValueName": "AllowServicePoweredQSA",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "EnableAutoUpgrade",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Suggested Sites",
    "RegItemValueName": "Enabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Ext",
    "RegItemValueName": "DisableAddonLoadTimePerformanceNotifications",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Recovery",
    "RegItemValueName": "AutoRecover",
    "RegItemValueType": "DWord",
    "RegItemValue": "2",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Geolocation",
    "RegItemValueName": "PolicyDisableGeolocation",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "DisableFirstRunCustomize",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Infodelivery\\Restrictions",
    "RegItemValueName": "NoSplash",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Infodelivery\\Restrictions",
    "RegItemValueName": "NoUpdateCheck",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\SQM",
    "RegItemValueName": "DisableCustomerImprovementProgram",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "TabProcGrowth",
    "RegItemValueType": "String",
    "RegItemValue": "Low",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "Play_Animations",
    "RegItemValueType": "String",
    "RegItemValue": "no",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "Play_Background_Sounds",
    "RegItemValueType": "String",
    "RegItemValue": "no",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
    "RegItemValueName": "Display Inline Videos",
    "RegItemValueType": "String",
    "RegItemValue": "no",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\FlipAhead",
    "RegItemValueName": "Enabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\PrefetchPrerender",
    "RegItemValueName": "Enabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main\\FormatDetection",
    "RegItemValueName": "PhoneNumberEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors",
    "RegItemValueName": "DisableLocation",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors",
    "RegItemValueName": "DisableSensors",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors",
    "RegItemValueName": "DisableWindowsLocationProvider",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Maps",
    "RegItemValueName": "AllowUntriggeredNetworkTrafficOnSettingsPage",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Maps",
    "RegItemValueName": "AutoDownloadAndUpdateMapData",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Messaging",
    "RegItemValueName": "AllowMessageSync",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\BooksLibrary",
    "RegItemValueName": "AllowConfigurationUpdateForBooksLibrary",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\ServiceUI",
    "RegItemValueName": "AllowWebContentOnNewTabPage",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\BooksLibrary",
    "RegItemValueName": "EnableExtendedBooksTelemetry",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\Main",
    "RegItemValueName": "AllowPrelaunch",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\TabPreloader",
    "RegItemValueName": "AllowTabPreloading",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\Main",
    "RegItemValueName": "PreventFirstRunPage",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Speech",
    "RegItemValueName": "AllowSpeechModelUpdate",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search",
    "RegItemValueName": "AllowCortanaAboveLock",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search",
    "RegItemValueName": "AllowSearchToUseLocation",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\WindowsInkWorkspace",
    "RegItemValueName": "AllowWindowsInkWorkspace",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Reliability Analysis\\WMI",
    "RegItemValueName": "WMIEnable",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search",
    "RegItemValueName": "PreventIndexingUncachedExchangeFolders",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR",
    "RegItemValueName": "AllowGameDVR",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\TextInput",
    "RegItemValueName": "AllowLinguisticDataCollection",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU",
    "RegItemValueName": "EnableFeaturedSoftware",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\FindMyDevice",
    "RegItemValueName": "AllowFindMyDevice",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "ConfigureWindowsSpotlight",
    "RegItemValueType": "DWord",
    "RegItemValue": "2",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "NoRemoteDestinations",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoSearchInternetInStartMenu",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "DisableThirdPartySuggestions",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "DisableTailoredExperiencesWithDiagnosticData",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoResolveSearch",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Directory UI",
    "RegItemValueName": "QueryLimit",
    "RegItemValueType": "DWord",
    "RegItemValue": "1500",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "NoWindowMinimizingShortcuts",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "TaskbarNoNotification",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
    "RegItemValueName": "DisableWindowsSpotlightFeatures",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoThumbnailCache",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "DisableSearchBoxSuggestions",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "NoBalloonFeatureAdvertisements",
    "RegItemValueType": "DWord",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Control Panel\\International",
    "RegItemValueName": "TurnOffOfferTextPredictions",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer",
    "RegItemValueName": "DisableThumbsDBOnNetworkFolders",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\PushNotifications",
    "RegItemValueName": "NoToastApplicationNotification",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\PushNotifications",
    "RegItemValueName": "NoToastApplicationNotificationOnLockScreen",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\EdgeUI",
    "RegItemValueName": "DisableMFUTracking",
    "RegItemValueType": "DWord",
    "RegItemValue": "1",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
    "RegItemValueName": "NoInstrumentation",
    "RegItemValueType": "DWord",
    "RegItemValue": "",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Edge\\Recommended",
    "RegItemValueName": "StartupBoostEnabled",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\EdgeUpdate",
    "RegItemValueName": "UpdatesSuppressedDurationMin",
    "RegItemValueType": "DWord",
    "RegItemValue": "900",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\EdgeUpdate",
    "RegItemValueName": "UpdatesSuppressedStartHour",
    "RegItemValueType": "DWord",
    "RegItemValue": "4",
    "VDIState": "Enabled"
  },
  {
    "RegItemPath": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\EdgeUpdate",
    "RegItemValueName": "UpdatesSuppressedStartMin",
    "RegItemValueType": "DWord",
    "RegItemValue": "0",
    "VDIState": "Enabled"
  }
]
"@
  # foreach ($Key in $Settings) {
  #     if (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction "SilentlyContinue") {
  #         Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force
  #     }
  #     else {
  #         if (Test-Path -Path $Key.RegItemPath) {
  #             New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force
  #         }
  #         else {
  #             New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force
  #         }

  #     }
  # }
  #endregion

  #region Edge Settings
  # https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/EdgeSettings.json
  $Settings = @"
[
    {
        "Description": "Allows Microsoft Edge processes to start at OS sign-in and keep running after the last browser window is closed.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "BackgroundModeEnabled",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    },
    {
        "Description": "If you enable this policy, the First-run experience and the splash screen will not be shown to users when they run Microsoft Edge for the first time.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "HideFirstRunExperience",
        "RegItemValueType": "DWord",
        "RegItemValue": "1",
        "VDIState": "Enabled"
    },
    {
        "Description": "This policy gives an option to disable one-time redirection dialog and the banner.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "HideInternetExplorerRedirectUXForIncompatibleSitesEnabled",
        "RegItemValueType": "DWord",
        "RegItemValue": "1",
        "VDIState": "Enabled"
    },
    {
        "Description": "This policy setting lets you decide whether employees should receive recommendations and in-product assistance notifications from Microsoft Edge.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "ShowRecommendationsEnabled",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    },
    {
        "Description": "This policy lets you restrict launching of Internet Explorer as a standalone browser",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Internet Explorer\\Main",
        "RegItemValueName": "NotifyDisableIEOptions",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    },
    {
        "Description": "This policy specifies the path to a file (e.g. either stored locally or on a network location) that contains file type and protocol default application associations.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "RegItemValueName": "DefaultAssociationsConfiguration",
        "RegItemValueType": "String",
        "RegItemValue": "c:\\windows\\system32\\defaultassociations.xml",
        "VDIState": "Unchanged"
    },
    {
        "Description": "Allows Microsoft Edge processes to start at OS sign-in and restart in background after the last browser window is closed.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "StartupBoostEnabled",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    },
    {
        "Description": "Efficiency mode is always active. Efficiency mode is designed to help reduce background processing and extend battery life. It minimizes power usage by reducing resource usage (CPU usage) through modifying certain tab activity on tabs you’re not interacting with and putting inactive background tabs to sleep after 5 minutes or less. Supported since Edge v96.",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "EfficiencyMode",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    },
    {
        "Description": "Policy setting to control an Edge search bar that gets placed on the user desktop automatically",
        "RegItemPath": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
        "RegItemValueName": "WebWidgetAllowed",
        "RegItemValueType": "DWord",
        "RegItemValue": "0",
        "VDIState": "Enabled"
    }
]
"@
  # foreach ($Key in $Settings) {
  #     if (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction "SilentlyContinue") {
  #         Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force
  #     }
  #     else {
  #         if (Test-Path -Path $Key.RegItemPath) {
  #             New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force
  #         }
  #         else {
  #             New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force
  #         }

  #     }
  # }
  #endregion

  #region Disk Cleanup
  Get-ChildItem -Path "$Env:SystemDrive\" -Include "*.tmp", "*.dmp", "*.etl", "*.evtx", "thumbcache*.db" -File -Recurse -Force -ErrorAction "SilentlyContinue" | `
    Remove-Item -ErrorAction "SilentlyContinue"

  # Delete "RetailDemo" content (if it exits)
  Get-ChildItem -Path "$Env:ProgramData\Microsoft\Windows\RetailDemo\*" -Recurse -Force -ErrorAction "SilentlyContinue" | `
    Remove-Item -Recurse -ErrorAction SilentlyContinue

  # Delete not in-use anything in the C:\Windows\Temp folder
  Remove-Item -Path "$Env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction "SilentlyContinue" -Exclude "packer*.ps1"

  # Clear out Windows Error Reporting (WER) report archive folders
  Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\WER\Temp\*" -Recurse -Force -ErrorAction "SilentlyContinue"
  Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -ErrorAction "SilentlyContinue"
  Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction "SilentlyContinue"

  # Delete not in-use anything in your %temp% folder
  Remove-Item -Path "$Env:TEMP\*" -Recurse -Force -ErrorAction "SilentlyContinue" -Exclude "packer*.ps1"

  # Clear out ALL visible Recycle Bins
  Clear-RecycleBin -Force -ErrorAction "SilentlyContinue"

  # Clear out BranchCache cache
  Clear-BCCache -Force -ErrorAction "SilentlyContinue"
  #endregion
}

end {
  $StopWatch.Stop()
  Write-Host "Stop: $ScriptName. Time: $($StopWatch.Elapsed)"
}
