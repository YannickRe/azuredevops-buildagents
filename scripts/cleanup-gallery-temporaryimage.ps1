param(
    [String] [Parameter (Mandatory=$true)] $ManagedImageName,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup
)

$managedImageId=$(az image list --resource-group $ResourceGroup --query "[?name=='$ManagedImageName'].id" --output tsv)

if ($managedImageId) {
    Write-Output "Retrieve generated managedImageId: $managedImageId"
    az image delete --ids $managedImageId | Out-Null
    Write-Output "Cleanup temporary created Managed Image"
}
else {
    Write-Output "Managed Image $ManagedImageName not found in Resource Group $ResourceGroup"
}