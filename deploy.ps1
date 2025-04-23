$TenantId = "9a95621c-b347-40ab-ab83-707f98942280"
$SubscriptionId = "27c99779-9397-4bd4-b7c0-2cde094b9646"
az login --tenant $TenantId --use-device-code
az account set --subscription $SubscriptionId

$Upn = (az account list --all | ConvertFrom-Json | Where-Object { $_.id -eq $SubscriptionId }).user.name | Select-Object -First 1
$Region = "australiaeast"

az deployment sub what-if --parameters upn=$Upn --location $Region --template-file ./1_main.bicep
az deployment sub create --parameters upn=$Upn --location $Region --template-file ./1_main.bicep

az role assignment create `
    --assignee "9cdead84-a844-4324-93f2-b2e6bb768d07" `
    --role "Azure Virtual Desktop Autoscale" `
    --scope "/subscriptions/$SubscriptionId"

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

foreach ($Container in ("scripts", "configs", "binaries")) {
    az storage blob upload-batch --source "./image/$Container" `
        --destination $Container `
        --account-name $StorageAccount.name `
        --overwrite
}

foreach ($Container in ("scripts", "configs", "binaries")) {
    az storage container set-permission `
        --name $Container `
        --account-name $StorageAccount.name `
        --public-access blob
}

az deployment sub create --parameters upn=$Upn --location $Region --template-file ./2_customimage.bicep

az image builder run --name "it-Avd-win11-23h2-avd-en-au-01" --resource-group "rg-Avd-Images-australiaeast" --no-wait

az extension add --upgrade -n desktopvirtualization

$ManagementRg = az group list | ConvertFrom-Json | Where-Object { $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Management" }
$KeyVault = az keyvault list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $ManagementRg.name -and $_.tags.Type -eq "Management" }

az keyvault set-policy --upn $Upn --name $KeyVault.name --secret-permissions set delete get list purge

az keyvault secret set --vault-name $KeyVault.name --name "vmAdministratorAccountUsername" --value "rmuser"
az keyvault secret set --vault-name $KeyVault.name --name "vmAdministratorAccountPassword" --value "Passw0rd"

az keyvault secret set --vault-name $KeyVault.name --name "administratorAccountUsername" --value "domain\joinaccount"
az keyvault secret set --vault-name $KeyVault.name --name "administratorAccountPassword" --value "Passw0rd"
az keyvault secret set --vault-name $KeyVault.name --name "ouPath" --value "OU=Azure Virtual Desktop,dc=domain,dc=local"
az keyvault secret set --vault-name $KeyVault.name --name "domain" --value "domain"

$HostPool = "vdpool-Avd-HostPool01-Pooled-aue"
$Output = az desktopvirtualization hostpool update `
    --name $HostPool `
    --resource-group $ManagementRg.name `
    --registration-info expiration-time=$((Get-Date).AddHours(72).ToString("yyyy-MM-ddTHH:mm:ss.fffK")) registration-token-operation="Update"
az keyvault secret set --vault-name $KeyVault.name --name "hostPoolToken-$HostPool" --value $($Output | ConvertFrom-Json).registrationInfo.token

$HostPoolRg = az group list | ConvertFrom-Json | Where-Object { $_.name -match "HostPool01" -and $_.tags.Application -eq "Azure Virtual Desktop" -and $_.tags.Type -eq "Pooled" }
$StorageAccount = az storage account list | ConvertFrom-Json | Where-Object { $_.resourceGroup -eq $HostPoolRg.name -and $_.tags.Type -eq "Pooled" }
$Output = az storage account keys list --account-name $StorageAccount.name | ConvertFrom-Json
$Output = az storage account keys list --account-name $StorageAccount.name | ConvertFrom-Json
az keyvault secret set --vault-name $KeyVault.name --name "storageAccountName-$HostPool" --value $StorageAccount.name
az keyvault secret set --vault-name $KeyVault.name --name "storageAccountKey-$HostPool" --value $Output[0].value

az deployment group create --parameters upn=$Upn --resource-group "rg-Avd-HostPool01-australiaeast" --template-file ./4_sessionhosts.bicep
