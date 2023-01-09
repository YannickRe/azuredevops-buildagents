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
    [String] [Parameter (Mandatory=$true)] $OsType,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroup
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$date = Get-Date
$GalleryImageVersion = $date.ToString("yyyy.MM.dd")
$GalleryVmImageDefinition = "$ImageType-agentpool-full"

$StorageAccountObject = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount 
$StorageAccountId = $StorageAccountObject.Id

$VmImageVersion = az sig image-version create --resource-group $ResourceGroup --gallery-name $GalleryName --gallery-image-definition $GalleryVmImageDefinition  --gallery-image-version $GalleryImageVersion --os-vhd-uri $OsVhdUri -os-vhd-storage-account $StorageAccountId

Write-Host "##vso[task.setvariable variable=$VmImageVersion;isOutput=true;]$VmImageVersion"

Write-Host "Created in $Gallery new $GalleryVmImageDefinition Version: $GalleryImageVersion"

$storageContainer = "Microsoft.Compute/Images/images/$ResourcesNamePrefix"
$existingBlobs = az storage blob list -c system --prefix $storageContainer --account-name $StorageAccount --auth-mode login --query "[].name" | Out-String
$existingBlobs = ConvertFrom-Json $existingBlobs

foreach ($blob in $existingBlobs) {
    Write-Host "Found a match, deleting Packer generated file $blob"
    az storage blob delete -c system -n $blob --account-name $StorageAccount --delete-snapshots include --auth-mode login
}