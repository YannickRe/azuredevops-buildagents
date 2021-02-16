param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $AgentsResourceGroup,
    [String] [Parameter (Mandatory=$true)] $VmssNameWindows,
    [String] [Parameter (Mandatory=$true)] $VmssNameUbuntu
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null

$managedImages = az image list --resource-group $ResourceGroup --subscription $SubscriptionId --query "[].id" | Out-String | ConvertFrom-Json

$windowsManagedImage = az vmss show --name $VmssNameWindows --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json
$ubuntuManagedImage = az vmss show --name $VmssNameUbuntu --resource-group $AgentsResourceGroup --query 'virtualMachineProfile.storageProfile.imageReference.id' --subscription $SubscriptionId | Out-String | ConvertFrom-Json

foreach ($managedImage in $managedImages) {
    if ($managedImage -ne $windowsManagedImage -and $managedImage -ne $ubuntuManagedImage) {
        Write-Host "Found a match, deleting orphaned managed image: $managedImage"
        az image delete --ids $managedImage | Out-Null
    }
}