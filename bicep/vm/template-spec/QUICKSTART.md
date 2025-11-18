# Windows VM Template Spec - Quick Start Guide

## 1. Setup Key Vault (One-time)

```bash
# Create Key Vault
az keyvault create \
  --name kv-vm-credentials \
  --resource-group rg-keyvault \
  --location eastus

# Store admin credentials
az keyvault secret set --vault-name kv-vm-credentials --name adminUsername --value "azureadmin"
az keyvault secret set --vault-name kv-vm-credentials --name adminPassword --value "YourSecurePassword123!"

# Store AD domain credentials (if using Active Directory)
az keyvault secret set --vault-name kv-vm-credentials --name adDomainName --value "contoso.com"
az keyvault secret set --vault-name kv-vm-credentials --name adDomainJoinUsername --value "contoso\\joiner"
az keyvault secret set --vault-name kv-vm-credentials --name adDomainJoinPassword --value "DomainPassword123!"
az keyvault secret set --vault-name kv-vm-credentials --name adOuPath --value "OU=Servers,DC=contoso,DC=com"

# Grant yourself access
az keyvault set-policy \
  --name kv-vm-credentials \
  --upn user@contoso.com \
  --secret-permissions get list
```

## 2. Deploy Template Spec (One-time)

```bash
cd /Users/aaron/projects/azurevirtualdesktop/bicep/vm/template-spec
./deploy.sh
```

Or with PowerShell:
```powershell
cd \Users\aaron\projects\azurevirtualdesktop\bicep\vm\template-spec
.\deploy.ps1
```

## 3. Deploy a VM

### Option A: Azure Portal
1. Go to **Template Specs** in Azure Portal
2. Select **windows-vm-simplified**
3. Click **Deploy**
4. Fill in the form and deploy

### Option B: Command Line

**Update main.bicepparam with your values**, then:

```bash
az deployment sub create \
  --location eastus \
  --template-spec "/subscriptions/{sub-id}/resourceGroups/rg-template-specs/providers/Microsoft.Resources/templateSpecs/windows-vm-simplified/versions/1.0.0" \
  --parameters main.bicepparam
```

## Key Points

✅ **All credentials** stored in Key Vault - never in code
✅ **Simple interface** - only essential options
✅ **Self-service** ready - can be delegated to users  
✅ **Secure by default** - Trusted Launch enabled
✅ **Flexible domain join** - None, AD, or Entra ID

## Parameters Quick Reference

**Always Required:**
- VM Name
- Resource Group
- Region
- Virtual Network + Subnet
- Key Vault
- Domain Join Type

**From Key Vault:**
- Admin Username & Password (always)
- AD Domain Credentials (if AD join)

**Optional (has defaults):**
- VM Size (Standard_D4s_v5)
- Disk Type (Premium_LRS)
- Windows Image (Windows 11 Enterprise)
- Availability Zone (Zone 1)
- Trusted Launch (enabled)

## Common Scenarios

### Scenario 1: Windows 11 workstation, no domain
```bicep
param domainJoinType = 'None'
param windowsImageType = 'Windows 11 Enterprise'
```

### Scenario 2: Windows Server with AD join
```bicep
param domainJoinType = 'ActiveDirectory'
param windowsImageType = 'Windows Server 2022 Datacenter'
// AD credentials retrieved from Key Vault
```

### Scenario 3: Windows 10 with Entra ID
```bicep
param domainJoinType = 'EntraID'
param windowsImageType = 'Windows 10 Enterprise'
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| Key Vault access denied | Run: `az keyvault set-policy --name <vault> --upn <user> --secret-permissions get list` |
| Subnet not found | Check subnet name spelling and case |
| VM size not available | Choose different size or region |
| Trusted Launch error | Set `enableTrustedLaunch = false` for older VM sizes |

## Next Steps

- **Monitor**: Check Azure Portal → Virtual Machines
- **Connect**: Use RDP or Bastion
- **Manage**: Apply policies, backups, monitoring
- **Repeat**: Deploy more VMs using the same Template Spec
