// ================================================================================
// Azure Windows Virtual Machine Deployment
// ================================================================================
// Deploys a Windows virtual machine with the following features:
// - Optional Trusted Launch security (Secure Boot and vTPM)
// - Standard VM support (for compatibility with specific VM sizes/images)
// - Zone deployment support
// - Client licensing for Windows 10/11
// - Active Directory or Entra ID domain join options
// - Configurable VM image, size, region, and disk type

metadata name = 'Windows Virtual Machine'
metadata description = 'Deploys a Windows VM into an existing virtual network with optional Trusted Launch security'
metadata owner = 'Cloud Team'

@description('The name of the virtual machine')
param vmName string

@description('Azure region for the VM deployment')
param location string = resourceGroup().location

@description('The availability zone for the VM (1, 2, 3, or empty for no zone)')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param availabilityZone string = ''

@description('Virtual machine size (e.g., Standard_D4s_v5)')
param vmSize string

@description('OS Disk storage type')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'StandardSSD_ZRS'
  'Premium_ZRS'
])
param osDiskType string

@description('VM image publisher')
param imagePublisher string

@description('VM image offer')
param imageOffer string

@description('VM image SKU')
param imageSku string

@description('VM image version (use "latest" for most recent)')
param imageVersion string = 'latest'

@description('Administrator username for the VM')
param adminUsername string

@description('Administrator password for the VM')
@secure()
param adminPassword string

@description('Resource ID of the existing virtual network')
param vnetResourceId string

@description('Name of the subnet in the virtual network')
param subnetName string

@description('Domain join type: None, ActiveDirectory, or EntraID')
@allowed([
  'None'
  'ActiveDirectory'
  'EntraID'
])
param domainJoinType string = 'None'

@description('Active Directory domain name (required if domainJoinType = ActiveDirectory)')
param adDomainName string = ''

@description('Active Directory domain join username (required if domainJoinType = ActiveDirectory)')
param adDomainJoinUsername string = ''

@description('Active Directory domain join password (required if domainJoinType = ActiveDirectory)')
@secure()
param adDomainJoinPassword string = ''

@description('Active Directory Organizational Unit path (optional)')
param adOuPath string = ''

@description('Enable Trusted Launch security (Secure Boot and vTPM)')
param enableTrustedLaunch bool = true

@description('Enable boot diagnostics')
param enableBootDiagnostics bool = true

@description('Run a custom PowerShell script after deployment')
param runCustomScript bool = false

@description('URL of the PowerShell script to execute')
param scriptUrl string = ''

@description('Name of the script file to execute (e.g., configure.ps1)')
param scriptFileName string = ''

@description('Arguments to pass to the PowerShell script')
param scriptArguments string = ''

@description('Tags to apply to resources')
param tags object = {}

// ================================================================================
// Variables
// ================================================================================

var nicName = '${vmName}-nic'
var isWindows10or11 = contains(toLower(imageSku), 'win10') || contains(toLower(imageSku), 'win11') || contains(
  toLower(imageSku),
  '10-'
) || contains(toLower(imageSku), '11-')
var enableClientLicense = isWindows10or11

var subnetResourceId = '${vnetResourceId}/subnets/${subnetName}'

// Security profile for Trusted Launch VMs (conditional)
var securityProfile = enableTrustedLaunch
  ? {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  : null

// License type for Windows client OS (Windows 10/11)
var licenseType = enableClientLicense ? 'Windows_Client' : 'Windows_Server'

// ================================================================================
// Resources
// ================================================================================

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetResourceId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  zones: !empty(availabilityZone) ? [availabilityZone] : []
  identity: {
    type: domainJoinType == 'EntraID' ? 'SystemAssigned' : 'None'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: enableTrustedLaunch ? securityProfile : null
    diagnosticsProfile: enableBootDiagnostics
      ? {
          bootDiagnostics: {
            enabled: true
          }
        }
      : {
          bootDiagnostics: {
            enabled: false
          }
        }
    licenseType: licenseType
  }
}

// Guest Attestation Extension (required for Trusted Launch)
resource guestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (enableTrustedLaunch) {
  parent: virtualMachine
  name: 'GuestAttestation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
      }
    }
  }
}

// Active Directory Domain Join Extension
resource adDomainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (domainJoinType == 'ActiveDirectory') {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: adDomainName
      ouPath: adOuPath
      user: adDomainJoinUsername
      restart: true
      options: 3
    }
    protectedSettings: {
      password: adDomainJoinPassword
    }
  }
}

// Entra ID (Azure AD) Join Extension
resource entraIdJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (domainJoinType == 'EntraID') {
  parent: virtualMachine
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

// Custom Script Extension (runs after domain join)
resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (runCustomScript) {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: !empty(scriptArguments)
        ? 'powershell -ExecutionPolicy Unrestricted -File ${scriptFileName} ${scriptArguments}'
        : 'powershell -ExecutionPolicy Unrestricted -File ${scriptFileName}'
    }
  }
  dependsOn: [
    adDomainJoinExtension
    entraIdJoinExtension
  ]
}

// ================================================================================
// Outputs
// ================================================================================

@description('Resource ID of the virtual machine')
output vmResourceId string = virtualMachine.id

@description('Name of the virtual machine')
output vmName string = virtualMachine.name

@description('Private IP address of the VM')
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('Zone where the VM is deployed')
output zone string = !empty(availabilityZone) ? availabilityZone : 'None'

@description('Domain join status')
output domainJoinType string = domainJoinType

@description('License type applied')
output licenseType string = licenseType

@description('Trusted Launch security status')
output trustedLaunchEnabled bool = enableTrustedLaunch

@description('Custom script execution status')
output customScriptEnabled bool = runCustomScript
