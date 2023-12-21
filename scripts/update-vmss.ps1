param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $AgentsResourceGroup,
    [String] [Parameter (Mandatory=$true)] $ManagedImageName,
    [String] [Parameter (Mandatory=$true)] $VmssNames
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$imageName = $ManagedImageName
$managedImageId=$(az image list --resource-group $ResourceGroup --query "[?name=='$imageName'].id" --output tsv)
Write-Host "Retrieve generated managedImageId: $managedImageId"

$VmssNames.Split(",") | ForEach-Object {
  $VmssName = $_
  az vmss update --resource-group $AgentsResourceGroup --name $VmssName --set virtualMachineProfile.storageProfile.imageReference.id=$ManagedImageId
  Write-Host "Updated Virtual Machine Scale Set ManagedImageId: $VmssName - $ManagedImageId"
}
