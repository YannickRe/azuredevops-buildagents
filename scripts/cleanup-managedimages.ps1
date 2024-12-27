param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $AgentsResourceGroup,
    [String] [Parameter (Mandatory=$true)] $VmssNameWindows,
    [String] [Parameter (Mandatory=$true)] $VmssNameWindows2022,
    [String] [Parameter (Mandatory=$true)] $VmssNameUbuntu,
    [String] [Parameter (Mandatory=$true)] $VmssNameUbuntu2204,
    [String] [Parameter (Mandatory=$true)] $VmssNameUbuntu2404
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$managedImages = az image list --resource-group $ResourceGroup --subscription $SubscriptionId --query "[].id" | Out-String | ConvertFrom-Json

$windowsManagedImage = az vmss show --name $VmssNameWindows --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json
$windowsManagedImage2022 = az vmss show --name $VmssNameWindows2022 --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json
$ubuntuManagedImage = az vmss show --name $VmssNameUbuntu --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json
$ubuntuManagedImage2204 = az vmss show --name $VmssNameUbuntu2204 --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json
$ubuntuManagedImage2404 = az vmss show --name $VmssNameUbuntu2404 --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json


foreach ($managedImage in $managedImages) {
    if ($managedImage -ne $windowsManagedImage -and $managedImage -ne $ubuntuManagedImage -and $managedImage -ne $windowsManagedImage2022 -and $managedImage -ne $ubuntuManagedImage2204 -and $managedImage -ne $ubuntuManagedImage2404) {
        Write-Host "Found a match, deleting orphaned managed image: $managedImage"
        az image delete --ids $managedImage | Out-Null
    }
}