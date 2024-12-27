param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ManagedImageName,
    [String] [Parameter (Mandatory=$true)] $BuildId,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryStorageAccountType,
    [String] [Parameter (Mandatory=$true)] $GalleryVmImageDefinition
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$imageName = $ManagedImageName
$managedImageId=$(az image list --resource-group $ResourceGroup --query "[?name=='$imageName'].id" --output tsv)
Write-Host "Retrieve generated managedImageId: $managedImageId"

$date = Get-Date
$GalleryImageVersion = "$($date.ToString("yyyyMMdd")).$BuildId.0"

$VmImageVersion = az sig image-version create -g $GalleryResourceGroup  --gallery-name $GalleryName --gallery-image-definition $GalleryVmImageDefinition --gallery-image-version $GalleryImageVersion --managed-image $ManagedImageId --storage-account-type $GalleryStorageAccountType --target-regions $Location
Write-Host "##vso[task.setvariable variable=VmImageVersion;]$VmImageVersion"

Write-Host "Update Gallery Image: $GalleryVmImageDefinition"
Write-Host "Created VM Image Version: $VMImageversion"

az image delete --ids $managedImageId | Out-Null
Write-Host "Cleanup temporary created Managed Image"
