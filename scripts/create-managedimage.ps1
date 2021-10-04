param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourcesNamePrefix,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $StorageAccount,
    [String] [Parameter (Mandatory=$true)] $ImageType,
    [String] [Parameter (Mandatory=$true)] $OsVhdUri,
    [String] [Parameter (Mandatory=$true)] $OsType
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$imageName = "$ImageType-$ResourcesNamePrefix"
$managedImageId = az image create -g $ResourceGroup -n $imageName --location $Location --os-type $OsType --source $OsVhdUri --query 'id'
Write-Host "##vso[task.setvariable variable=ManagedImageId;isOutput=true;]$managedImageId"

Write-Host "Created Managed Image: $imageName"

$storageContainer = "Microsoft.Compute/Images/images/$ResourcesNamePrefix"
$existingBlobs = az storage blob list -c system --prefix $storageContainer --account-name $StorageAccount --auth-mode login --query "[].name" | Out-String
$existingBlobs = ConvertFrom-Json $existingBlobs

foreach ($blob in $existingBlobs) {
    Write-Host "Found a match, deleting Packer generated file $blob"
    az storage blob delete -c system -n $blob --account-name $StorageAccount --delete-snapshots include --auth-mode login
}