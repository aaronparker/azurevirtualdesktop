@description('Location for all resources to be created in')
param location string = 'australiaeast'

@description('The availability option for the VMs')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'AvailabilityZone'

@description('The name of availability set to be used when create the VMs')
param availabilitySetName string = ''

@description('The availability zones to equally distribute VMs amongst')
param availabilityZones array = [1,2,3]

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory')
param rdshPrefix string = 'avd-aue-' // take(toLower(resourceGroup().name), 10)

@description('Number of session hosts that will be created and added to the hostPool')
param rdshNumberOfInstances int = 1

@description('The VM disk type for the VM: HDD or SSD')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_ZRS'
])
param rdshVMDiskType string = 'StandardSSD_LRS'

@description('The size of the session host VMs')
param rdshVmSize string = 'Standard_D2as_v5'

// @description('The size of the disk on the vm in GB')
// param rdshVmDiskSizeGB int = 0

@description('Whether or not the VM is hibernate enabled')
param rdshHibernate bool = false

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs')
param enableAcceleratedNetworking bool = true

@description('The username for the domain admin')
@secure()
param administratorAccountUsername string

@description('The password that corresponds to the existing domain username')
@secure()
param administratorAccountPassword string

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used')
@secure()
param vmAdministratorAccountUsername string

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used')
@secure()
param vmAdministratorAccountPassword string

@description('The unique id of the subnet for the NICs')
param subnetId string

@description('Resource ID of the image')
param rdshImageSourceId string

@description('The EdgeZone extended location of the session host VMs')
param extendedLocation object = {}

@description('The tags to be assigned to the images')
param tags object = {
  'cm-resource-parent': '/subscriptions/3fc4c8ac-a2b8-4b39-9729-f1a5eeacbab5/resourcegroups/rg-AvdManagement-australiaeast/providers/Microsoft.DesktopVirtualization/hostPools/vdpool-hostPool01-Pooled-aue'
}

@description('VM name prefix initial number')
param vmInitialNumber int = 1
//param _guidValue string = newGuid()

@description('The token for adding VMs to the hostPool')
@secure()
param hostPoolToken string

@description('The name of the hostPool')
param hostPoolName string

@description('OUPath for the domain join')
@secure()
param ouPath string = ''

@description('Domain to join')
@secure()
param domain string = ''

@description('Storage account name to use for FSLogix Profile Container')
@secure()
param storageAccountName string = ''

@description('Storage account key to use for FSLogix Profile Container')
@secure()
param storageAccountKey string = ''

@description('True if Entra join, false if AD join')
param entraJoin bool = true

@description('True if intune enrollment is selected.  False otherwise')
param intune bool = true

@description('Boot diagnostics object taken as body of Diagnostics Profile in VM creation')
param bootDiagnostics object = {
  enabled: true
}

@description('The name of user assigned identity that will assigned to the VMs. This is an optional parameter')
param userAssignedIdentity string = ''

@description('The PowerShell script URL to be run as part of post update custom configuration')
param customConfigurationScriptUrl string = ''

@description('The arguments to be passed to the custom configuration script')
var scriptArguments = '-StorageAccount "${storageAccountName}" -StorageAccountKey "${storageAccountKey}"'

@description('Session host configuration version of the host pool')
param SessionHostConfigurationVersion string = ''

@description('System data is used for internal purposes, such as support preview features')
param systemData object = {}

@description('Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings. Default: UefiSettings will not be enabled unless this property is set as TrustedLaunch')
@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
param securityType string = 'TrustedLaunch'

@description('Specifies whether secure boot should be enabled on the virtual machine')
param secureBoot bool = true

@description('Specifies whether vTPM (Virtual Trusted Platform Module) should be enabled on the virtual machine')
param vTPM bool = true

@description('Specifies whether integrity monitoring will be added to the virtual machine')
param integrityMonitoring bool = true

@description('Managed disk security encryption type')
@allowed([
  'VMGuestStateOnly'
  'DiskWithVMGuestState'
])
param managedDiskSecurityEncryptionType string = 'VMGuestStateOnly'

var artifactsLocation = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_1.0.02705.330.zip'
var emptyArray = []
var domainName = ((domain == '') ? last(split(administratorAccountUsername, '@')) : domain)
var storageAccountType = rdshVMDiskType

var isVMAdminAccountCredentialsProvided = ((vmAdministratorAccountUsername != '') && (vmAdministratorAccountPassword != ''))
var vmAdministratorUsername = (isVMAdminAccountCredentialsProvided
  ? vmAdministratorAccountUsername
  : first(split(administratorAccountUsername, '@')))
var vmAdministratorPassword = (isVMAdminAccountCredentialsProvided
  ? vmAdministratorAccountPassword
  : administratorAccountPassword)
var vmAvailabilitySetResourceId = {
  id: resourceId('Microsoft.Compute/availabilitySets/', availabilitySetName)
}
var vmIdentityType = (entraJoin
  ? ((!empty(userAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned')
  : ((!empty(userAssignedIdentity)) ? 'UserAssigned' : 'None'))
var vmIdentityTypeProperty = {
  type: vmIdentityType
}
var vmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/',userAssignedIdentity)}': {}
  }
}
var vmIdentity = ((!empty(userAssignedIdentity))
  ? union(vmIdentityTypeProperty, vmUserAssignedIdentityProperty)
  : vmIdentityTypeProperty)
var powerShellScriptName = (empty(customConfigurationScriptUrl) ? null : last(split(customConfigurationScriptUrl, '/')))
var securityProfile = {
  uefiSettings: {
    secureBootEnabled: secureBoot
    vTpmEnabled: vTPM
  }
  securityType: securityType
}
var managedDiskSecurityProfile = {
  securityEncryptionType: managedDiskSecurityEncryptionType
}
var countOfSelectedAZ = length(availabilityZones)

resource SessionHostVirtualMachineNic 'Microsoft.Network/networkInterfaces@2023-11-01' = [for i in range(0, rdshNumberOfInstances): {
    name: '${rdshPrefix}${(i+vmInitialNumber)}-nic'
    location: location
    extendedLocation: (empty(extendedLocation) ? null : extendedLocation)
    tags: tags
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: subnetId
            }
          }
        }
      ]
      enableAcceleratedNetworking: enableAcceleratedNetworking
      networkSecurityGroup: null
    }
    dependsOn: []
  }
]

resource SessionHostVirtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(0, rdshNumberOfInstances): {
    name: '${rdshPrefix}${(i+vmInitialNumber)}'
    location: location
    extendedLocation: (empty(extendedLocation) ? null : extendedLocation)
    tags: tags
    zones: ((availabilityOption == 'AvailabilityZone') ? array(availabilityZones[(i % countOfSelectedAZ)]) : emptyArray)
    identity: vmIdentity
    plan: null
    properties: {
      hardwareProfile: {
        vmSize: rdshVmSize
      }
      availabilitySet: ((availabilityOption == 'AvailabilitySet') ? vmAvailabilitySetResourceId : null)
      osProfile: {
        computerName: '${rdshPrefix}${(i + vmInitialNumber)}'
        adminUsername: vmAdministratorUsername
        adminPassword: vmAdministratorPassword
      }
      securityProfile: (((securityType == 'TrustedLaunch') || (securityType == 'ConfidentialVM'))
        ? securityProfile
        : null)
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: storageAccountType
            securityProfile: ((securityType == 'ConfidentialVM') ? managedDiskSecurityProfile : null)
          }
        }
        imageReference: {
          id: rdshImageSourceId
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: SessionHostVirtualMachineNic[i].id //resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i+vmInitialNumber)}-nic')
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: bootDiagnostics
      }
      additionalCapabilities: {
        hibernationEnabled: rdshHibernate
      }
      licenseType: 'Windows_Client'
    }
    dependsOn: [
      SessionHostVirtualMachineNic
    ]
  }
]

resource GuestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): if (integrityMonitoring) {
    name: '${rdshPrefix}${(i+vmInitialNumber)}/GuestAttestation'
    location: location
    properties: {
      publisher: 'Microsoft.Azure.Security.WindowsAttestation'
      type: 'GuestAttestation'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      settings: {
        AttestationConfig: {
          MaaSettings: {
            maaEndpoint: ''
            maaTenantName: 'GuestAttestation'
          }
          AscSettings: {
            ascReportingEndpoint: ''
            ascReportingFrequency: ''
          }
          useCustomToken: 'false'
          disableAlerts: 'false'
        }
      }
    }
    dependsOn: [
      SessionHostVirtualMachine[i]
    ]
  }
]

resource PowerShellDscExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): {
    name: '${rdshPrefix}${(i+vmInitialNumber)}/Microsoft.PowerShell.DSC'
    location: location
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.73'
      autoUpgradeMinorVersion: true
      settings: {
        modulesUrl: artifactsLocation
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        properties: {
          hostPoolName: hostPoolName
          registrationInfoTokenCredential: {
            UserName: 'PLACEHOLDER_DO_NOT_USE'
            Password: 'PrivateSettingsRef:RegistrationInfoToken'
          }
          aadJoin: entraJoin
          UseAgentDownloadEndpoint: true
          aadJoinPreview: (contains(systemData, 'aadJoinPreview') && systemData.aadJoinPreview)
          mdmId: (intune ? '0000000a-0000-0000-c000-000000000000' : '')
          sessionHostConfigurationLastUpdateTime: SessionHostConfigurationVersion
        }
      }
      protectedSettings: {
        Items: {
          registrationInfoToken: hostPoolToken
        }
      }
    }
    dependsOn: [
      GuestAttestationExtension[i]
    ]
  }
]

resource AadLoginForWindowsExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): if (entraJoin && (contains(systemData, 'entraJoinPreview')
    ? (!systemData.entraJoinPreview)
    : bool('true'))) {
    name: '${rdshPrefix}${(i+vmInitialNumber)}/AADLoginForWindows'
    location: location
    properties: {
      publisher: 'Microsoft.Azure.ActiveDirectory'
      type: 'AADLoginForWindows'
      typeHandlerVersion: '2.0'
      autoUpgradeMinorVersion: true
      settings: (intune
        ? {
            mdmId: '0000000a-0000-0000-c000-000000000000'
          }
        : null)
    }
    dependsOn: [
      PowerShellDscExtension[i]
    ]
  }
]

resource AdDomainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): if (!entraJoin) {
    name: '${rdshPrefix}${(i+vmInitialNumber)}/joindomain'
    location: location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'JsonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: true
      settings: {
        name: domainName
        ouPath: ouPath
        user: administratorAccountUsername
        restart: 'true'
        options: '3'
      }
      protectedSettings: {
        password: administratorAccountPassword
      }
    }
    dependsOn: [
      PowerShellDscExtension[i]
    ]
  }
]

resource IaaSAntimalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): if (!empty(customConfigurationScriptUrl)) {
  name: '${rdshPrefix}${(i+vmInitialNumber)}/IaaSAntimalware'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        day: 7
        time: 120
        scanType: 'Quick'
      }
      Exclusions: {
        Extensions: null
        Paths: '%TEMP%\\*\\*.VHDX;%Windir%\\TEMP\\*\\*.VHDX'
        Processes: null
      }
    }
  }
  dependsOn: [
    PowerShellDscExtension[i]
    AadLoginForWindowsExtension[i]
    AdDomainJoinExtension[i]
  ]
}]

resource CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, rdshNumberOfInstances): if (!empty(customConfigurationScriptUrl)) {
    name: '${rdshPrefix}${(i+vmInitialNumber)}/Microsoft.Compute.CustomScriptExtension'
    location: location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.10'
      autoUpgradeMinorVersion: true
      protectedSettings: {
        fileUris: [
          customConfigurationScriptUrl
        ]
        commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${powerShellScriptName} ${scriptArguments}'
      }
    }
    dependsOn: [
      IaaSAntimalwareExtension[i]
      PowerShellDscExtension[i]
      AadLoginForWindowsExtension[i]
      AdDomainJoinExtension[i]
    ]
  }
]
