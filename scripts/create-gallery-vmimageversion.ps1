param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourcesNamePrefix,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroup,
    [String] [Parameter (Mandatory=$true)] $ImageType,
    [String] [Parameter (Mandatory=$true)] $ManagedImageId
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$date = Get-Date
$ImageVersion = $date.ToString("yyyy.MM.dd")

$GalleryVmImageDefinition = "$ImageType-agentpool-full"
$VmImageVersion = az gallery image version  create -g $GalleryResourceGroup  --gallery-name $GalleryName --gallery-image-definition $GalleryVmImageDefinition --name $ImageVersion --manage-image $ManagedImageId

Write-Host "##vso[task.setvariable variable=VmImageVersion;isOutput=true;]$VmImageVersion"

Write-Host "Update Gallery Image: $GalleryImageDefinition"
Write-Host "Created VM Image Version: $VMImageversion"

