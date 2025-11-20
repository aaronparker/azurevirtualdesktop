# Windows Virtual Machine Deployment - Bicep Template

This Bicep template deploys a Windows virtual machine into an existing Azure virtual network with the following enterprise features:

## Features

- **Trusted Launch Security**: Optional Trusted Launch VMs with Secure Boot and vTPM (enabled by default)
- **Standard VMs**: Option to deploy without Trusted Launch for compatibility with older VM sizes or images
- **Zone Deployment**: Supports deployment into availability zones 1, 2, or 3
- **Client Licensing**: Automatically detects Windows 10/11 images and enables Windows_Client licensing
- **Domain Join Options**: 
  - No domain join
  - Active Directory domain join
  - Entra ID (Azure AD) join
- **Custom Script Execution**: Run PowerShell scripts from URLs after VM deployment and domain join
- **Configurable Parameters**: All key settings (VM size, image, disk type, region) are parameterized
- **Best Practices**: Includes automatic updates, managed disks, and boot diagnostics

## Prerequisites

- An existing Azure Virtual Network and subnet
- Appropriate permissions to deploy VMs and extensions
- For Active Directory domain join: Domain join credentials
- For Entra ID join: Entra ID tenant configured for device registration
- Azure Key Vault to store sensitive credentials (admin username/password, domain join credentials)

## Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `vmName` | Name of the virtual machine | `testVM01` |
| `vmSize` | Azure VM size | `Standard_D4as_v5` |
| `osDiskType` | Storage type for OS disk | `StandardSSD_LRS` |
| `imagePublisher` | VM image publisher | `MicrosoftWindowsDesktop` |
| `imageOffer` | VM image offer | `Windows-11` |
| `imageSku` | VM image SKU | `win11-24h2-ent` |
| `adminUsername` | Administrator username | `azureadmin` |
| `adminPassword` | Administrator password (secure) | *provided at runtime* |
| `vnetResourceId` | Resource ID of existing VNet | `/subscriptions/.../virtualNetworks/myVNet` |
| `subnetName` | Subnet name in the VNet | `default` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `location` | Azure region | Resource group location |
| `availabilityZone` | Availability zone (1, 2, 3, or empty) | `''` (no zone) |
| `imageVersion` | Image version | `latest` |
| `domainJoinType` | Domain join type | `None` |
| `enableTrustedLaunch` | Enable Trusted Launch security | `true` |
| `enableBootDiagnostics` | Enable boot diagnostics | `true` |
| `tags` | Resource tags | `{}` |

### Active Directory Domain Join Parameters

Only required when `domainJoinType = 'ActiveDirectory'`:

| Parameter | Description |
|-----------|-------------|
| `adDomainName` | AD domain name (e.g., `contoso.com`) |
| `adDomainJoinUsername` | Domain join account username |
| `adDomainJoinPassword` | Domain join account password |
| `adOuPath` | Organizational Unit path (optional) |

### Custom Script Execution Parameters

Optional parameters for running PowerShell scripts after deployment:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `runCustomScript` | Enable custom script execution | `false` |
| `scriptUrl` | URL of PowerShell script to download and execute | `''` |
| `scriptFileName` | Name of the script file | `''` |
| `scriptArguments` | Arguments to pass to the script | `''` |

**Note**: Custom script execution runs after domain join (if configured) completes.

## Supported Operating Systems

Windows desktop image available on Azure can be found here: [https://az-vm-image.info/?cmd=--all+--publisher+MicrosoftWindowsDesktop](https://az-vm-image.info/?cmd=--all+--publisher+MicrosoftWindowsDesktop). This list should show the Windows desktop images available, including basic Windows 10 and Windows 11 images, as well as images that include the Microsoft 365 apps. 

### Windows 11 Images (Client Licensing Enabled)

```bicep
imagePublisher: 'MicrosoftWindowsDesktop'
imageOffer: 'Windows-11'
imageSku: 'win11-24h2-ent'  // Enterprise, also use win11-23h2-ent, win11-25h2-ent etc.
imageSku: 'win11-24h2-avd'  // Enterprise Multi-session (AVD), also use win11-23h2-avd, win11-25h2-avd etc.
```

### Windows 10 Images (Client Licensing Enabled)

```bicep
imagePublisher: 'MicrosoftWindowsDesktop'
imageOffer: 'Windows-10'
imageSku: 'win10-22h2-ent'  // Enterprise
imageSku: 'win10-22h2-entn'  // Enterprise Multi-session (AVD)
```

### Windows Server Images

```bicep
// Windows Server 2022 Datacenter Azure Edition
imagePublisher: 'MicrosoftWindowsServer'
imageOffer: 'WindowsServer'
imageSku: '2022-datacenter-azure-edition'

// Windows Server 2025 Datacenter
imageSku: '2025-datacenter-g2'

// Windows Server 2022 Datacenter
imageSku: '2022-datacenter-g2'

// Windows Server 2019 Datacenter
imageSku: '2019-datacenter-g2'
```

## Disk Types

Supported OS disk types:
- `Standard_LRS` - Standard HDD, locally redundant
- `StandardSSD_LRS` - Standard SSD, locally redundant
- `Premium_LRS` - Premium SSD, locally redundant
- `StandardSSD_ZRS` - Standard SSD, zone-redundant
- `Premium_ZRS` - Premium SSD, zone-redundant

## Deployment Examples

### Example: Windows 11 with Entra ID Join

Update `main.bicepparam`:

```bicep
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageOffer = 'Windows-11'
param imageSku = 'win11-24h2-ent'
param domainJoinType = 'EntraID'
```

Deploy:

```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

### Example: Standard VM without Trusted Launch

For VM sizes or images that don't support Trusted Launch:

Update `main.bicepparam`:
```bicep
param enableTrustedLaunch = false
param vmSize = 'Standard_B2s'  // Example: older VM size
```

Deploy:
```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

### Example 4: Using Azure Key Vault for Secrets

Use the `main.bicepparam` file to reference secrets stored in Azure Key Vault:

1. Create secrets in your Key Vault:
```powershell
az keyvault secret set --vault-name myKeyVault --name adminUsername --value "azureadmin"
az keyvault secret set --vault-name myKeyVault --name adminPassword --value "<secure-password>"
az keyvault secret set --vault-name myKeyVault --name adDomainName --value "contoso.com"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinUsername --value "contoso\\joiner"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinPassword --value "<domain-password>"
az keyvault secret set --vault-name myKeyVault --name adOuPath --value "OU=Servers,DC=contoso,DC=com"
```

2. Update `main.bicepparam` with your Key Vault details:

```bicep
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminPassword')
```

3. Deploy:
```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

**Note**: The deployment identity (user or service principal) must have `Get` and `List` permissions on Key Vault secrets.

### Example: Windows Server with Active Directory Domain Join

Update `main.bicepparam`:

```bicep
param domainJoinType = 'ActiveDirectory'
param adDomainName = 'contoso.com'
param adDomainJoinUsername = 'contoso\\joiner'
param adOuPath = 'OU=Servers,DC=contoso,DC=com'
```

Deploy:

```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

### Example: Windows Server with Custom Script Execution

Update `main.bicepparam` to run a script after deployment:

```bicep
param runCustomScript = true
param scriptUrl = 'https://stavddsplbxuncheac.blob.core.windows.net/scripts/Install-Agents.ps1'
param scriptFileName = 'Install-Agents.ps1'
param scriptArguments = ''
```

Deploy:

```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

### Example: AD Domain Join + Custom Script

Combine domain join with script execution:

```bicep
param domainJoinType = 'ActiveDirectory'
param adDomainName = 'contoso.com'
param adDomainJoinUsername = 'contoso\\joiner'
param runCustomScript = true
param scriptUrl = 'https://storage.blob.core.windows.net/scripts/post-domain-join.ps1'
param scriptFileName = 'post-domain-join.ps1'
```

**Note**: The custom script executes after domain join completes successfully.

## Trusted Launch vs Standard VMs

### Trusted Launch VMs (Default)

Trusted Launch provides enhanced security through:
- **Secure Boot**: Protects against bootkit and rootkit malware
- **vTPM (Virtual Trusted Platform Module)**: Enables measured boot and cryptographic operations
- **Guest Attestation**: Validates boot integrity

**Use Trusted Launch when:**
- Security is a priority (recommended for production workloads)
- Using supported VM sizes (most Generation 2 VMs)
- Deploying Windows 11, Windows 10, or Windows Server 2016+

### Standard VMs

Standard VMs without Trusted Launch may be required when:
- Using older VM sizes that don't support Trusted Launch
- Using specific marketplace images incompatible with Trusted Launch
- Legacy application compatibility requirements

**To deploy a Standard VM**, set `enableTrustedLaunch = false` in your parameters file:

```bicep
param enableTrustedLaunch = false
```

### Checking Trusted Launch Support

Verify if your VM size supports Trusted Launch:

```powershell
# Check VM size capabilities
az vm list-sizes --location eastus --query "[?contains(name, 'Standard_D4s_v5')]"

# Verify image supports Trusted Launch
az vm image show `
  --location eastus `
  --publisher MicrosoftWindowsDesktop `
  --offer Windows-11 `
  --sku win11-23h2-ent `
  --version latest `
  --query "hyperVGeneration"
```

## Azure Key Vault Integration

### Setting Up Key Vault for Secure Deployments

Azure Key Vault integration allows you to securely store and reference sensitive credentials without exposing them in parameters files or command lines.

#### Step 1: Create Key Vault and Store Secrets

```powershell
# Create a Key Vault (if not already created)
az keyvault create `
  --name myKeyVault `
  --resource-group myKeyVaultRG `
  --location eastus `
  --enable-rbac-authorization false

# Store admin credentials
az keyvault secret set --vault-name myKeyVault --name adminUsername --value "azureadmin"
az keyvault secret set --vault-name myKeyVault --name adminPassword --value "YourSecurePassword123!"

# Store AD domain join credentials (if using Active Directory)
az keyvault secret set --vault-name myKeyVault --name adDomainName --value "contoso.com"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinUsername --value "contoso\\joiner"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinPassword --value "YourDomainPassword123!"
az keyvault secret set --vault-name myKeyVault --name adOuPath --value "OU=Servers,DC=contoso,DC=com"
```

#### Step 2: Grant Access to Deployment Identity

```powershell
# For user-based deployment
az keyvault set-policy `
  --name myKeyVault `
  --upn user@contoso.com `
  --secret-permissions get list

# For service principal-based deployment
az keyvault set-policy `
  --name myKeyVault `
  --spn <service-principal-id> `
  --secret-permissions get list
```

#### Step 3: Reference Secrets in Parameters File

Use the `main.bicepparam` file or update `main.bicepparam` with `getSecret()` calls:

```bicep
// Format: getSecret('subscription-id', 'resource-group', 'keyvault-name', 'secret-name')
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminPassword')
param adDomainName = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainName')
param adDomainJoinUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainJoinPassword')
param adOuPath = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adOuPath')
```

#### Step 4: Deploy Using Key Vault

```powershell
az deployment group create `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

### Key Vault Best Practices

1. **Use RBAC**: Enable RBAC authorization on Key Vault for fine-grained access control
2. **Separate Key Vaults**: Use different Key Vaults for different environments (dev, staging, production)
3. **Soft Delete**: Enable soft delete and purge protection to prevent accidental deletion
4. **Audit Logs**: Enable diagnostic settings to track secret access
5. **Managed Identities**: Use managed identities for automated deployments instead of service principals when possible

## Zone Support

To deploy into an availability zone, set the `availabilityZone` parameter:

```bicep
param availabilityZone = '1'  // Use zone 1
param availabilityZone = '2'  // Use zone 2
param availabilityZone = '3'  // Use zone 3
param availabilityZone = ''   // No zone (regional deployment)
```

**Note**: Not all VM sizes and regions support availability zones. Verify zone support for your chosen VM size and region.

## Client Licensing

The template automatically detects Windows 10 and Windows 11 images and applies the `Windows_Client` license type, which enables:

- Proper licensing for client operating systems
- Correct billing for Windows client VMs
- Compliance with Microsoft licensing terms

Detection is based on the image SKU containing:
- `win10` or `10-` for Windows 10
- `win11` or `11-` for Windows 11

Windows Server images automatically use `Windows_Server` licensing.

## Security Features

### Trusted Launch (Optional)

Trusted Launch is enabled by default and provides enhanced security:
- **Secure Boot**: Ensures the VM boots only with trusted bootloaders and kernel
- **vTPM**: Virtual Trusted Platform Module for cryptographic operations and attestation
- **Guest Attestation Extension**: Validates the VM's security posture

To disable Trusted Launch (for compatibility with specific VM sizes or images), set:
```bicep
param enableTrustedLaunch = false
```

### Domain Join Security

- **Active Directory**: Uses the `JsonADDomainExtension` to securely join on-premises or Azure-hosted AD domains
- **Entra ID**: Uses the `AADLoginForWindows` extension for cloud-native identity management
- System-assigned managed identity is enabled for Entra ID joined VMs

## Outputs

The template provides the following outputs:

| Output | Description |
|--------|-------------|
| `vmResourceId` | Full resource ID of the virtual machine |
| `vmName` | Name of the virtual machine |
| `privateIpAddress` | Private IP address assigned to the VM |
| `zone` | Availability zone (or 'None') |
| `domainJoinType` | Domain join configuration applied |
| `licenseType` | License type applied (Windows_Client or Windows_Server) |
| `trustedLaunchEnabled` | Whether Trusted Launch security is enabled |
| `customScriptEnabled` | Whether custom script execution was enabled |

## Customization

### Adding Data Disks

To add data disks, modify the `storageProfile` section:

```bicep
storageProfile: {
  // ... existing configuration ...
  dataDisks: [
    {
      name: '${vmName}-datadisk1'
      lun: 0
      createOption: 'Empty'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
  ]
}
```

### Custom Extensions

Add additional VM extensions after the existing ones:

```bicep
resource customExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      // Your configuration
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Zone Not Supported**: Verify that your VM size supports zones in the target region
2. **Image Not Found**: Ensure the publisher, offer, and SKU are valid for your region
3. **Trusted Launch Not Supported**: If deployment fails with Trusted Launch errors, verify your VM size and image support Trusted Launch, or set `enableTrustedLaunch = false`
4. **Domain Join Fails**: Check domain join credentials, network connectivity to domain controllers, and OU path syntax
5. **Entra ID Join Fails**: Verify the Azure AD tenant is configured for device registration
6. **Custom Script Fails**: Check script URL accessibility, script syntax, execution policy, and review VM extension logs in Azure Portal

### Validation

Validate the template before deployment:

```powershell
az deployment group validate `
  --resource-group myResourceGroup `
  --template-file main.bicep `
  --parameters main.bicepparam
```

## Best Practices

1. **Use Trusted Launch**: Enable Trusted Launch for production workloads (default) unless VM size or image compatibility requires Standard VMs
2. **Use Key Vault**: Store passwords in Azure Key Vault and reference them in parameters
3. **Backup**: Configure Azure Backup for production VMs
4. **Monitoring**: Enable Azure Monitor and diagnostic settings
5. **Updates**: Use Azure Update Management for patch management
6. **Tagging**: Apply consistent tags for cost management and governance
7. **Naming**: Follow a consistent naming convention for resources
8. **Script Security**: Host custom scripts in secure locations (e.g., Azure Blob Storage with SAS tokens or private GitHub repos) and use HTTPS URLs
9. **Script Testing**: Test PowerShell scripts locally before deploying via Custom Script Extension

## References

- [Trusted Launch for Azure VMs](https://learn.microsoft.com/azure/virtual-machines/trusted-launch)
- [Azure Hybrid Benefit](https://azure.microsoft.com/pricing/hybrid-benefit/)
- [Windows Client in Azure](https://learn.microsoft.com/azure/virtual-machines/windows/client-images)
- [Join a Windows VM to Entra ID](https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-windows)
- [Join a Windows VM to Active Directory](https://learn.microsoft.com/azure/active-directory-domain-services/join-windows-vm)
