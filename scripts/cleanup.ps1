param(
    [String] [Parameter (Mandatory=$true)] $Image,
    [String] [Parameter (Mandatory=$true)] $ResourcesNamePrefix,
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $StorageAccount
)

az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId | Out-Null
az account set -s $SubscriptionId

$TempResourceGroupName = "${ResourcesNamePrefix}_${Image}"

$groupExist = az group exists --name $TempResourceGroupName --subscription $SubscriptionId
if ($groupExist -eq "true") {
    Write-Host "Found a match, deleting temporary files"
    az group delete --name $TempResourceGroupName --subscription $SubscriptionId --yes | Out-Null
    Write-Host "Temporary group was deleted succesfully" -ForegroundColor Green
} else {
    Write-Host "No temporary groups found"
}

$existingBlobs = az storage blob list -c images --prefix $ResourcesNamePrefix --account-name $StorageAccount --auth-mode login --query "[].name" | Out-String
$existingBlobs = ConvertFrom-Json $existingBlobs

foreach ($blob in $existingBlobs) {
    Write-Host "Found a match, deleting temporary vhd: $blob"
    az storage blob delete -c images -n $blob --account-name $StorageAccount --delete-snapshots include --auth-mode login
}