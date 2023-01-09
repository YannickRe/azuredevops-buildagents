param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourcesNamePrefix,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $ImageType,
    [String] [Parameter (Mandatory=$true)] $GalleryVMImageDefinition,
    [String] [Parameter (Mandatory=$true)] $ManagedImageId
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$date = Get-Date
$ImageVersion = $date.ToString("yyyy.MM.dd")

$GalleryVMImageDefinition = "$ImageType-agentpool-full"
$VmImageVersion = az gallery image version  create -g $ResourceGroup  --gallery-name $GalleryName --$GalleryImageDefinition -name $ImageVersion -manage-image $ManagedImageId

Write-Host "##vso[task.setvariable variable=ManagedImageId;isOutput=true;]$VmImageVersion"

Write-Host "Update Gallery Image: $GalleryImageDefinition"
Write-Host "Created VM Image Version: $VMImageversion"



#az gallery image version create \
#  --resource-group myResourceGroup \
#  --gallery-name myGallery \
#  --gallery-image-definition myImageDefinition \
#  --name myImageVersion \
#  --managed-image '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}'
