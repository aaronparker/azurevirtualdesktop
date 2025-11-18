# Azure Key Vault Integration Guide

## Overview

This guide explains how to use Azure Key Vault to securely manage credentials for the Windows VM Bicep template deployment.

## Secure Parameters

The following parameters can be stored in Azure Key Vault:

- `adminUsername` - VM administrator username
- `adminPassword` - VM administrator password
- `adDomainName` - Active Directory domain name
- `adDomainJoinUsername` - Domain join account username
- `adDomainJoinPassword` - Domain join account password
- `adOuPath` - Organizational Unit path for domain join

## Quick Start

### 1. Create Key Vault and Store Secrets

```bash
# Create Key Vault
az keyvault create \
  --name myKeyVault \
  --resource-group myKeyVaultRG \
  --location eastus

# Store secrets
az keyvault secret set --vault-name myKeyVault --name adminUsername --value "azureadmin"
az keyvault secret set --vault-name myKeyVault --name adminPassword --value "P@ssw0rd123!"
az keyvault secret set --vault-name myKeyVault --name adDomainName --value "contoso.com"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinUsername --value "contoso\\joiner"
az keyvault secret set --vault-name myKeyVault --name adDomainJoinPassword --value "DomainP@ss123!"
az keyvault secret set --vault-name myKeyVault --name adOuPath --value "OU=Servers,DC=contoso,DC=com"
```

### 2. Grant Access

```bash
# For your user account
az keyvault set-policy \
  --name myKeyVault \
  --upn user@contoso.com \
  --secret-permissions get list

# For a service principal (CI/CD pipelines)
az keyvault set-policy \
  --name myKeyVault \
  --spn <service-principal-app-id> \
  --secret-permissions get list
```

### 3. Deploy Using Key Vault

**Option A: Use the provided Key Vault parameters file**

```bash
# Update main.keyvault.bicepparam with your subscription ID, resource group, and Key Vault name
# Then deploy:
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters main.keyvault.bicepparam
```

**Option B: Modify main.bicepparam to use Key Vault**

Edit `main.bicepparam` and replace the parameter assignments:

```bicep
// Replace these lines
param adminUsername = 'azureadmin'
param adminPassword = ''

// With these (update with your subscription ID, resource group, and Key Vault name)
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminPassword')
```

## getSecret() Syntax

The `getSecret()` function retrieves secrets from Azure Key Vault:

```bicep
getSecret('subscription-id', 'resource-group-name', 'keyvault-name', 'secret-name')
```

Parameters:
- `subscription-id`: Azure subscription ID where the Key Vault exists
- `resource-group-name`: Resource group containing the Key Vault
- `keyvault-name`: Name of the Key Vault
- `secret-name`: Name of the secret to retrieve

## Example Scenarios

### Scenario 1: Basic VM with Key Vault Credentials

```bicep
param adminUsername = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminPassword')
param domainJoinType = 'None'
```

### Scenario 2: VM with Active Directory Join and Key Vault

```bicep
param adminUsername = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminPassword')
param domainJoinType = 'ActiveDirectory'
param adDomainName = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adDomainName')
param adDomainJoinUsername = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adDomainJoinPassword')
param adOuPath = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adOuPath')
```

### Scenario 3: Hybrid - Some Values from Key Vault, Others Direct

You can mix Key Vault references with direct values:

```bicep
// Sensitive credentials from Key Vault
param adminUsername = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('12345678-1234-1234-1234-123456789012', 'kv-rg', 'myKeyVault', 'adminPassword')

// Non-sensitive values directly in parameters file
param vmName = 'myWindowsVM'
param location = 'eastus'
param vmSize = 'Standard_D4s_v5'
param domainJoinType = 'None'
```

## Security Considerations

### Key Vault Access Policies

The deployment identity must have the following permissions on the Key Vault:
- **Secret permissions**: `Get`, `List`

These are minimum required permissions. Additional permissions may be needed for other operations.

### RBAC vs Access Policies

**Access Policies** (Traditional):
```bash
az keyvault set-policy \
  --name myKeyVault \
  --upn user@contoso.com \
  --secret-permissions get list
```

**RBAC** (Recommended):
```bash
# Enable RBAC authorization on Key Vault
az keyvault update \
  --name myKeyVault \
  --enable-rbac-authorization true

# Assign role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee user@contoso.com \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/myKeyVault
```

### Network Security

For production environments, consider:
1. **Private Endpoints**: Connect to Key Vault over a private network
2. **Firewall Rules**: Restrict Key Vault access to specific IP ranges or VNets
3. **Service Endpoints**: Enable VNet service endpoints for Key Vault

```bash
# Add firewall rule
az keyvault network-rule add \
  --name myKeyVault \
  --ip-address "203.0.113.0/24"

# Add VNet rule
az keyvault network-rule add \
  --name myKeyVault \
  --vnet-name myVNet \
  --subnet mySubnet
```

## Troubleshooting

### Error: "The user, group or application does not have secrets get permission"

**Solution**: Grant secret permissions to the deployment identity
```bash
az keyvault set-policy \
  --name myKeyVault \
  --upn user@contoso.com \
  --secret-permissions get list
```

### Error: "Secret not found"

**Solution**: Verify the secret exists and the name is correct
```bash
# List all secrets
az keyvault secret list --vault-name myKeyVault

# Verify specific secret
az keyvault secret show --vault-name myKeyVault --name adminUsername
```

### Error: "Key Vault does not exist"

**Solution**: Verify the subscription ID, resource group, and Key Vault name are correct in the `getSecret()` call

### Error: "Key Vault is behind a firewall"

**Solution**: Add your deployment source IP to the Key Vault firewall or disable the firewall temporarily
```bash
az keyvault update \
  --name myKeyVault \
  --default-action Allow
```

## Best Practices

1. **Separate Key Vaults by Environment**: Use different Key Vaults for dev, test, and production
2. **Naming Convention**: Use consistent secret names across environments
3. **Secret Rotation**: Regularly rotate secrets and update Key Vault
4. **Audit Logging**: Enable diagnostic settings to track secret access
5. **Soft Delete**: Enable soft delete and purge protection
6. **Backup**: Regularly backup Key Vault secrets
7. **Least Privilege**: Grant minimum required permissions
8. **Managed Identities**: Use managed identities for service-to-service authentication

## CI/CD Integration

### Azure DevOps Pipeline Example

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'MyServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az deployment group create \
        --resource-group $(resourceGroup) \
        --template-file bicep/vm/main.bicep \
        --parameters bicep/vm/main.keyvault.bicepparam
```

### GitHub Actions Example

```yaml
name: Deploy VM

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy VM
      run: |
        az deployment group create \
          --resource-group ${{ secrets.RESOURCE_GROUP }} \
          --template-file bicep/vm/main.bicep \
          --parameters bicep/vm/main.keyvault.bicepparam
```

## Files Modified

The following files have been updated to support Key Vault integration:

1. **main.bicep** - No changes required; parameters remain the same
2. **main.bicepparam** - Added comments and examples showing Key Vault usage
3. **main.keyvault.bicepparam** - New file demonstrating Key Vault references (RECOMMENDED)
4. **README.md** - Added comprehensive Key Vault documentation
5. **KEYVAULT.md** - This guide (new)

## Additional Resources

- [Azure Key Vault Documentation](https://learn.microsoft.com/azure/key-vault/)
- [Bicep getSecret() function](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions-parameters-file#getsecret)
- [Integrate Key Vault with Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/key-vault-parameter)
- [Best practices for using Key Vault](https://learn.microsoft.com/azure/key-vault/general/best-practices)
