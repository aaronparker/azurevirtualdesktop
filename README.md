# Azure Virtual Desktop Deployment

Azure Bicep, image scripts, and policy configurations for Azure Virtual Desktop.

## Azure Bicep Templates

[Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) templates for a multi-region deployment of Azure Virtual Desktop. This assumes that you are using the Azure CLI under PowerShell on Windows, macOS or Linux.

The current status of resources deployed by these templates is:

**Core services**:

- [x] Standardised naming convention
- [x] Required subscription roles
- [x] Resource groups and tags
- [x] Virtual network and subnets
- [x] Custom DNS settings on virtual networks
- [x] Network security group
- [x] NAT gateway and public IP address
- [x] Private DNS zone for private endpoints
- [x] Route table (for use where networks need to be peered)
- [ ] Connect route table to the virtual network
- [x] Azure compute gallery
- [x] Standard tier storage accounts for image artefacts
- [x] Availability sets (for regions that don't support availability zones)
- [x] Premium tier storage accounts, private endpoints, profilecontainer share (FSLogix Containers)
- [ ] Configure Entra ID or AD DS authentication for storage accounts
- [ ] Private endpoints for more services e.g. Key vault
- [x] Log Analytics workspace for Azure Virtual Desktop Insights
- [x] Key vault

**AVD services (if Nerdio Manager is not available)**:

- [x] Image templates and custom images
- [x] Managed identity for Azure Image Builder
- [x] Host pools (with RDP settings), desktop application groups
- [ ] Additional host pool settings (e.g. RDP Shortpath)
- [x] Pooled host pool scaling plans
- [ ] Scaling plan -> host pool assignment
- [ ] Link application groups to the workspace
- [ ] Application group desktop display name
- [ ] RemoteApp application groups
- [x] Workspaces
- [ ] Private network access and Private endpoints for workspaces and host pools
- [x] Session host deployment into a host pool with a custom image
- [ ] Session host deployment into a host pool with a marketplace image
- [x] Validate Entra ID join and Intune enrolment during session host deployment
- [x] Store access key in session hosts for storage account authentication for Entra ID-only environments (FSLogix Containers)
- [x] Registry settings in session hosts to enable FSLogix Profile Container
- [ ] Replace session hosts with a new image
- [ ] Connect AVD objects to the Log Analytics workspace
- [ ] 'Virtual Machine User Login' assignment on host pool resource groups
- [ ] Assignments on application groups
- [ ] App attach applications and configuration

### Setup

Install the following tools:

* [Azure Az PowerShell module](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

Install tools on Windows:

```powershell
Install-Module -Name az
winget install Microsoft.Bicep --silent
winget install Microsoft.AzureCLI --silent
```

Install tools on macOS:

```powershell
Install-Module -Name az
brew install azure/bicep/bicep
brew install azure-cli
```

### Authentication

Sign into the target Azure environment with an account that has at least Contributor rights on the target subscription. Owner rights will be required configure roles and permissions on the subscription.

Sign into the environment using the Azure CLI (note, login via device code may be disabled in some environments):

```powershell
$TenantId = "8a95621c-b347-40ab-ab83-707f98942280"
$SubscriptionId = "27c99779-9397-4bd4-b7c0-2cde094b9646"
az login --tenant $TenantId --use-device-code
az account set --subscription $SubscriptionId
```

After signing in, set your UPN and the target region for deployments as a variable to use later:

```powershell
$Upn = (az account list --all | ConvertFrom-Json | Where-Object { $_.id -eq $SubscriptionId }).user.name | Select-Object -First 1
$Region = "australiaeast"
```

#### Authentication Issues

If you receive the following message when running `az` commands below used to set permissions:

```text
User cancelled the Accounts Control Operation.. Status: Response_Status.Status_UserCanceled, Error code: 0, Tag: 528315210
Please explicitly log in with:
az login
```

Run this command:

```bash
az config set core.enable_broker_on_windows=false
```

### Enable Resource Providers

The following resource providers must be enabled on the target subscription:

- Microsoft.Compute
- Microsoft.KeyVault
- Microsoft.Storage
- Microsoft.Network
- Microsoft.ContainerInstance
- Microsoft.DesktopVirtualization

Register these providers with:

```powershell
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Network
az provider register -n Microsoft.ContainerInstance
az feature register --namespace Microsoft.VirtualMachineImages --name Triggers
az provider register -n Microsoft.VirtualMachineImages
```

### Bicep Templates

#### Parameter Files

Parameter files are used by the Bicep templates to define the deployment including regions that services will be deployed into:

* `regions.json` -  defines one or more regions that services will be deployed into.  Enable a region for deployment by setting `"deployRegion": true`. To deploy a premium tier storage account for FSLogix Containers (e.g. pooled desktops) set `deployStorage": true`. Deploy a NAT gateway in each virtual network by setting `"deployNatGateway": true`
* `abbreviations.json` - abbreviations used when naming Azure services. Prefixes are aligned to the Microsoft recommendations - [Define your naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). **Note**: update the `service` value for the target environment
* `tags.json` - values for some key tags - review and update these
* `customimages.json` - defines a custom image for AVD session hosts using the Azure Image Builder. The template is configured to deploy the `PooledDesktop` image
* `rdpsettings.json` - defines the advanced RDP properties to configure on host pools
* `roles.json` - defines custom Entra ID roles to be used by the Azure Virtual Desktop service

#### Tags

All resources deployed by these templates are tagged with

* `Application` - defaults to `Azure Virtual Desktop`. Use to define the service that the resource is providing. Defined in `tags.json`
* `Criticality` - Use `High`, `Medium`, `Low` - criticality is defined on the resource group values in `regions.json`
* `Environment` - Use `Production`, `Test`, `Development` etc. Defined in `tags.json`
* `Function` - this value is defined on the resource group values in `regions.json`
* `LastUpdateBy` - this value should be the UPN of the person doing the deployment
* `LastUpdateDate` - this value is automatically calculated
* `Owner` - this value an be whatever is required. Defined in `tags.json`
* `Type` - this value is defined on the resource group values in `regions.json` and set specifically for some resources in the templates. The value should ideally not be changed, so that it can be used to query for specific resource types

#### 1_main.bicep

`1_main.bicep` defines an Azure Virtual Desktop deployment into a dedicated subscription, including:

* Resource groups for shared components
* Virtual networks (and subnets), NAT gateways (set `"deployNatGateway": true`), route tables
* Azure compute gallery, image definitions, and standard tier storage accounts (to host image related binaries and configurations)
* Premium tier storage accounts (with private endpoints) for pooled host pools (storage deployment can be specified as true/false. Storage names can be specified or automatically generated)
* A key vault and Log Analytics workspace per region
* Availability sets for host pools in regions that don't support availability zones
* Host pools and application groups to be created in the target regions
* An AVD workspace per region

#### 2_customimage.bicep

`2_customimage.bicep` defines custom images to be created in the target regions. Images are defined in `regions.json` including whether images are enabled for that region with `"deployImages": true`.

Not all regions support Azure Image Builder, see [Regions](https://learn.microsoft.com/en-us/azure/virtual-machines/image-builder-overview?tabs=azure-powershell#regions). You may need to create images in a region different to where AVD session hosts are deployed into. Ensure the `replicationRegions` in `regions.json` is defined with the target for replicated images.

#### 4_sessionhosts.bicep

`4_sessionhosts.bicep` is used to deploy session hosts from a custom image. This template requires parameters to be set in the file - it does not read `regions.json`. If you're at this stage, you can use this Bicep template or [WVDAdmin](https://www.itprocloud.com/wvdadmin/) to deploy session hosts.

### Validate Deployment

Validate what will be deployed with by running a `what-if` on the Bicep template (location is where the deployment will run, not necessarily where resources are deployed to):

```powershell
az deployment sub what-if --parameters upn=$Upn --location $Region --template-file ./1_main.bicep
```

#### Deploy

When you're ready to deploy, use the Azure CLI `create` command:

```powershell
az deployment sub create --parameters upn=$Upn --location $Region --template-file ./1_main.bicep
```

#### Subscription Permissions

Assign the Azure Virtual Desktop application to the auto-scale role on the subscription - the following code will assign the Azure Virtual Desktop application directly (the assignee GUID is the Azure Virtual Desktop application which is the same )

```powershell
az role assignment create `
    --assignee "9cdead84-a844-4324-93f2-b2e6bb768d07" `
    --role "Azure Virtual Desktop Autoscale" `
    --scope "/subscriptions/$SubscriptionId"
```

### Custom Images

#### Permissions

Configure permissions for the managed identity before creating the custom image template: [Configure Azure VM Image Builder permissions by using the Azure CLI](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-permissions-cli).

Add the `Azure Virtual Desktop Image Builder` role to the `Images` and `Network` resource groups, and configure permissions to blog storage with containers for scripts, configs etc.

```powershell
$ImagesRg = az group list | ConvertFrom-Json | Where-Object { $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Images" }
$StorageAccount = az storage account list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $ImagesRg.name -and $_.tags.Type -eq "Images" }

$ManagedId = az identity list | ConvertFrom-Json | Where-Object { $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Images" }
az role assignment create --assignee $ManagedId.clientId --role "Azure Virtual Desktop Image Builder" --scope "/subscriptions/$SubscriptionId/resourceGroups/$($ImagesRg.name)"

foreach ($Container in ("scripts", "configs", "binaries")) {
    az role assignment create `
        --assignee $ManagedId.clientId `
        --role "Storage Blob Data Reader" `
        --scope "/subscriptions/$SubscriptionId/resourceGroups/$($ImagesRg.name)/providers/Microsoft.Storage/storageAccounts/$($StorageAccount.name)/blobServices/default/containers/$Container"
}
```

#### Network configuration

**Note**: this section can be skipped - the Bicep templates will configure image builds in an isolated vnet.

Network configuration is required to use Azure Image Builder to build custom images in an existing virtual network. See [Use Azure VM Image Builder for Linux VMs to access an existing Azure virtual network](https://learn.microsoft.com/en-au/azure/virtual-machines/linux/image-builder-vnet).

The following commands assume a single AVD deployment in the target subscription.

```powershell
$NetworkRg = az group list | ConvertFrom-Json | Where-Object { $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Network" }
$Network = az network vnet list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $NetworkRg.name -and $_.tags.Type -eq "Network" }

az network vnet subnet update `
  --name Images `
  --resource-group $NetworkRg.name `
  --vnet-name $Network.name `
  --private-link-service-network-policies Disabled
```

#### Upload Scripts

**Note**: do not store secret values in scripts or configurations.

Before uploading scripts, review and update the paths scripts including `202_Microsoft365Apps.ps1` for URLs on the images storage account that are referenced.

The custom image will use scripts and configs stored in blob storage on the images storage account. Copy the scripts and configs from the `/image` directory to the blob containers in the storage account. Update the storage account with changes as required.

```powershell
foreach ($Container in ("scripts", "configs", "binaries")) {
    az storage blob upload-batch --source "./image/$Container" `
        --destination $Container `
        --account-name $StorageAccount.name `
        --overwrite
}
```

Once scripts and configs have been added to the storage account, update the script URL references in the `customImage.json` parameters file, then create the custom image template.

**Note**: if scripts need to be updated, copy them into the images storage account, then delete the image template and re-deploy with `2_customImage.bicep`.

#### Blob Access Level

**Note**: do not store secret values in scripts or configurations. This access level is needed until authentication to the account can be used.

Change the access level on the containers to `Blob (anonymous read access for blobs only)`. This is needed to enable scripts to download configuration files or scripts to execute during session host deployment.

```powershell
foreach ($Container in ("scripts", "configs", "binaries")) {
    az storage container set-permission `
        --name $Container `
        --account-name $StorageAccount.name `
        --public-access blob
}
```

#### Custom image templates

Create the custom image templates defined in `regions.json`:

```powershell
az deployment sub create --parameters upn=$Upn --location $Region --template-file ./2_customImage.bicep
```

Custom images can be viewed from the resource group, or in the [Custom image templates](https://portal.azure.com/#view/Microsoft_Azure_WVD/WvdManagerMenuBlade/~/customImageTemplate) in the Azure Virtual Desktop blade in the Azure portal.

**Note**: start the custom images from the Azure Virtual Desktop blade, otherwise Sysprep will not run at the end of the image build process.

### Host Pools Storage Accounts

Configure integration with Entra ID or AD DS authentication for authentication to storage accounts:

- [Enable Active Directory Domain Services authentication for Azure file shares](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable)
- [Enable Microsoft Entra Kerberos authentication for hybrid identities on Azure Files](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-hybrid-identities-enable?tabs=azure-portal)

### Deploy Session Hosts

Create the host pool registration key - note that this command sets a lifetime of 72 hours (use a lifetime of no more than 168 hours):

```powershell
az extension add --upgrade -n desktopvirtualization

$ManagementRg = az group list | ConvertFrom-Json | Where-Object { $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Management" }

$HostPool = "vdpool-Avd-HostPool01-Pooled-aue"
az desktopvirtualization hostpool update `
    --name $HostPool `
    --resource-group $ManagementRg.name `
    --registration-info expiration-time=$((Get-Date).AddHours(72).ToString("yyyy-MM-ddTHH:mm:ss.fffK")) registration-token-operation="Update"
```

Create key vault secrets used when session hosts are deployed:

```powershell
$KeyVault = az keyvault list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $ManagementRg.name -and $_.tags.Type -eq "Management" }

az keyvault set-policy --upn $Upn --name $KeyVault.name --secret-permissions set delete get list purge

az keyvault secret set --vault-name $KeyVault.name --name "vmAdministratorAccountUsername" --value "rmuser"
az keyvault secret set --vault-name $KeyVault.name --name "vmAdministratorAccountPassword" --value "Passw0rd"

az keyvault secret set --vault-name $KeyVault.name --name "administratorAccountUsername" --value "domain\joinaccount"
az keyvault secret set --vault-name $KeyVault.name --name "administratorAccountPassword" --value "Passw0rd"
az keyvault secret set --vault-name $KeyVault.name --name "ouPath" --value "OU=Azure Virtual Desktop,dc=domain,dc=local"
az keyvault secret set --vault-name $KeyVault.name --name "domain" --value "domain"
```

Grab the registration token for a target host pool and store in the key vault:

```powershell
$Output = az desktopvirtualization hostpool update `
    --name $HostPool `
    --resource-group $ManagementRg.name `
    --registration-info expiration-time=$((Get-Date).AddHours(72).ToString("yyyy-MM-ddTHH:mm:ss.fffK")) registration-token-operation="Update"
az keyvault secret set --vault-name $KeyVault.name --name "hostPoolToken-$HostPool" --value $($Output | ConvertFrom-Json).registrationInfo.token
```

**Note**: if you deploy virtual machines successfully, but they don't appear as session hosts in the host pool, update the host pool registration key in the key vault.

Deploy session hosts into the host pool (update the target resource group):

```powershell
az deployment group create --parameters upn=$Upn --resource-group "rg-AvdHostPool01-australiaeast" --template-file ./4_sessionHosts.bicep
```

#### Deployment Time Configuration

During deployment of session hosts, `SessionHostDeployment.ps1` will be run in each session host via the custom script extension. Review the code to see what that script does.

#### Storage Account Keys

`SessionHostDeployment.ps1` will attempt to save credentials for the storage account used to host FSLogix Containers with `cmdkey`. This approach is only for cloud-only user identities and is not required for hybrid user accounts (storage accounts that are AD joined or Entra joined support user access via hybrid accounts).

**Note**: some security configurations including enabling Credential Guard will prevent the access key being stored on the session host with `cmdkey`

Store details for access to a storage account for FSLogix Containers in the key vault:

```powershell
$HostPoolRg = az group list | ConvertFrom-Json | Where-Object { $_.name -match "HostPool01" -and $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Pooled" }
$StorageAccount = az storage account list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $HostPoolRg.name -and $_.tags.Type -eq "Pooled" }
$Output = az storage account keys list --account-name $StorageAccount.name | ConvertFrom-Json
az keyvault secret set --vault-name $KeyVault.name --name "storageAccountName-$HostPool" --value $StorageAccount.name
az keyvault secret set --vault-name $KeyVault.name --name "storageAccountKey-$HostPool" --value $Output[0].value
```

## Clean up

### Logout

Logout of the target environment and clear cached accounts with the following commands. This ensures that your next deployment requires a login and you don't deploy into the incorrect environment:

```
az logout
az account clear
```

### Delete resources

If these templates are used for testing and you need to remove the deployment, the following Azure CLI commands can be used to delete the resource groups:

```powershell
az group list | ConvertFrom-Json | Where-Object { $_.name -match "^rg-Avd" } | % { az group delete --name $_.name --yes }
```

You may also need to purge deleted key vaults when deleting resources and attempting to re-deploy:

```powershell
az keyvault purge --name $KeyVault.name
```
