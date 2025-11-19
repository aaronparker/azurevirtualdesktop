# Windows VM Template Spec - Simplified Deployment

This Azure Template Spec provides a simplified interface for deploying Windows virtual machines with Azure Key Vault integration for secure credential management.

## Overview

The Template Spec wraps the main Windows VM Bicep template with a user-friendly interface that only exposes essential configuration options, making it ideal for self-service VM deployments.

## Features

- **Simplified Interface**: Only essential parameters exposed (VM name, region, network, Key Vault, domain join)
- **Key Vault Integration**: All credentials securely retrieved from Azure Key Vault
- **Pre-configured Images**: Select from Windows 11, Windows 10, or Windows Server
- **Domain Join Options**: None, Active Directory, or Entra ID (Azure AD)
- **Security**: Trusted Launch enabled by default
- **Azure Portal UI**: Custom form for easy portal-based deployments

## Prerequisites

1. **Azure Key Vault** with the following secrets:
   - `adminUsername` - VM administrator username
   - `adminPassword` - VM administrator password
   - `adDomainName` - Active Directory domain name (if using AD join)
   - `adDomainJoinUsername` - Domain join account username (if using AD join)
   - `adDomainJoinPassword` - Domain join account password (if using AD join)
   - `adOuPath` - Organizational Unit path (optional, for AD join)

2. **Existing Virtual Network** with a subnet for VM deployment

3. **Permissions**:
   - Contributor role on target subscription/resource group
   - Key Vault Secret User role on the Key Vault

## Deployment Methods

### Method 1: Deploy Template Spec to Azure

First, publish the Template Spec to your Azure subscription:

**Using Bash:**
```bash
cd template-spec
chmod +x deploy.sh
./deploy.sh
```

**Using PowerShell:**
```powershell
cd template-spec
.\deploy.ps1
```

This creates the Template Spec in resource group `rg-template-specs`.

### Method 2: Deploy VM from Template Spec

#### Option A: Azure Portal

1. Navigate to **Template Specs** in Azure Portal
2. Select `windows-vm-simplified`
3. Click **Deploy**
4. Fill out the form:
   - **VM Name**: Name for your virtual machine
   - **Resource Group**: Target resource group (created if doesn't exist)
   - **Region**: Azure region
   - **Virtual Network**: Select existing VNet
   - **Subnet**: Subnet name
   - **Key Vault**: Select your Key Vault
   - **Domain Join**: Choose None, Active Directory, or Entra ID
5. Review and create

#### Option B: Azure CLI

```bash
# Get Template Spec ID
TEMPLATE_SPEC_ID=$(az ts show \
  --name windows-vm-simplified \
  --resource-group rg-template-specs \
  --version 1.0.0 \
  --query id -o tsv)

# Deploy with parameters file
az deployment sub create \
  --location eastus \
  --template-spec "$TEMPLATE_SPEC_ID" \
  --parameters main.bicepparam
```

#### Option C: PowerShell

```powershell
# Get Template Spec
$templateSpec = Get-AzTemplateSpec `
  -Name windows-vm-simplified `
  -ResourceGroupName rg-template-specs `
  -Version 1.0.0

# Deploy
New-AzSubscriptionDeployment `
  -Location eastus `
  -TemplateSpecId $templateSpec.Versions[0].Id `
  -TemplateParameterFile main.bicepparam
```

## Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `vmName` | Virtual machine name | `testVM0101` |
| `resourceGroupName` | Resource group name | `rg-windows-vms` |
| `location` | Azure region | `eastus` |
| `vnetResourceId` | Virtual network resource ID | `/subscriptions/.../virtualNetworks/vnet-main` |
| `subnetName` | Subnet name | `subnet-vms` |
| `keyVaultResourceId` | Key Vault resource ID | `/subscriptions/.../vaults/kv-credentials` |
| `domainJoinType` | Domain join option | `None`, `ActiveDirectory`, or `EntraID` |
| `adminUsername` | Admin username from Key Vault | Retrieved via `getSecret()` |
| `adminPassword` | Admin password from Key Vault | Retrieved via `getSecret()` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vmSize` | VM size | `Standard_D4s_v5` |
| `osDiskType` | OS disk storage type | `Premium_LRS` |
| `availabilityZone` | Availability zone (1, 2, 3, or empty) | `1` |
| `windowsImageType` | Windows image selection | `Windows 11 Enterprise` |
| `enableTrustedLaunch` | Enable Trusted Launch security | `true` |

### Domain Join Parameters (AD only)

When `domainJoinType = 'ActiveDirectory'`, these are retrieved from Key Vault:

| Parameter | Description |
|-----------|-------------|
| `adDomainName` | AD domain name |
| `adDomainJoinUsername` | Domain join username |
| `adDomainJoinPassword` | Domain join password |
| `adOuPath` | OU path (optional) |

## Example: Parameters File

Update `main.bicepparam` with your values:

```bicep
param vmName = 'testVM0101'
param resourceGroupName = 'rg-windows-vms'
param location = 'eastus'
param vnetResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main'
param subnetName = 'subnet-vms'
param keyVaultResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-keyvault/providers/Microsoft.KeyVault/vaults/kv-credentials'
param domainJoinType = 'ActiveDirectory'

// Credentials from Key Vault
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adminPassword')
param adDomainName = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainName')
param adDomainJoinUsername = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainJoinPassword')
param adOuPath = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adOuPath')
```

## Available Windows Images

| Image Type | Publisher | Offer | SKU |
|------------|-----------|-------|-----|
| Windows 11 Enterprise | MicrosoftWindowsDesktop | Windows-11 | win11-23h2-ent |
| Windows 10 Enterprise | MicrosoftWindowsDesktop | Windows-10 | win10-22h2-ent |
| Windows Server 2022 | MicrosoftWindowsServer | WindowsServer | 2022-datacenter-azure-edition |
| Windows Server 2019 | MicrosoftWindowsServer | WindowsServer | 2019-datacenter-gensecond |

## Outputs

| Output | Description |
|--------|-------------|
| `vmResourceId` | Resource ID of the deployed VM |
| `vmName` | VM name |
| `privateIpAddress` | Private IP address |
| `zone` | Availability zone |
| `domainJoinType` | Domain join configuration |
| `licenseType` | License type applied |
| `trustedLaunchEnabled` | Trusted Launch status |
| `resourceGroupName` | Resource group name |

## Security Considerations

1. **Key Vault Access**: Ensure deployment identity has `Get` and `List` permissions on Key Vault secrets
2. **Network Security**: VM is deployed into existing VNet - ensure appropriate NSG rules
3. **Trusted Launch**: Enabled by default for enhanced security
4. **Credentials**: Never stored in templates or parameter files - only in Key Vault

## Troubleshooting

### Error: "The user does not have secrets get permission"

**Solution**: Grant Key Vault access to deployment identity:
```bash
az keyvault set-policy \
  --name kv-credentials \
  --upn user@contoso.com \
  --secret-permissions get list
```

### Error: "Template Spec not found"

**Solution**: Ensure you've deployed the Template Spec first using `deploy.sh` or `deploy.ps1`

### Error: "Subnet not found"

**Solution**: Verify the subnet name matches exactly, including case sensitivity

## File Structure

```
template-spec/
├── main.bicep              # Template Spec Bicep template
├── main.bicepparam         # Parameters file example
├── uiFormDefinition.json   # Azure Portal UI definition
├── deploy.sh               # Bash deployment script
├── deploy.ps1              # PowerShell deployment script
└── README.md               # This file
```

## Updating the Template Spec

To publish a new version:

1. Update `main.bicep` or `uiFormDefinition.json`
2. Increment version in deployment script
3. Run `deploy.sh` or `deploy.ps1`

## Related Documentation

- [Main VM Template](../README.md)
- [Key Vault Integration Guide](../KEYVAULT.md)
- [Azure Template Specs Documentation](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs)

## Support

For issues or questions:
1. Review the main [VM template documentation](../README.md)
2. Check Key Vault secrets are correctly configured
3. Verify network and permissions are properly set up

## License

This template is provided as-is under the MIT License.
