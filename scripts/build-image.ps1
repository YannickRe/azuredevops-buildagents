param(
    [String] [Parameter (Mandatory=$true)] $TemplatePath,
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $ResourcesNamePrefix,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $StorageAccount,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $CaptureNamePrefix,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $ImageType, 
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkName,
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkRG,
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkSubnet

    )

if (-not (Test-Path $TemplatePath))
{
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$Image = [io.path]::GetFileName($TemplatePath).Split(".")[0]
$TempResourceGroupName = "${ResourcesNamePrefix}_${Image}"
$InstallPassword = [System.GUID]::NewGuid().ToString().ToUpper()

packer validate -syntax-only $TemplatePath

$SensitiveData = @(
    'OSType',
    'StorageAccountLocation',
    'OSDiskUri',
    'OSDiskUriReadOnlySas',
    'TemplateUri',
    'TemplateUriReadOnlySas',
    ':  ->'
)

Write-Host "Show Packer Version"
packer --version

Write-Host "Build $Image VM"
packer build    -var "client_id=$ClientId" `
                -var "client_secret=$ClientSecret" `
                -var "install_password=$InstallPassword" `
                -var "location=$Location" `
                -var "subscription_id=$SubscriptionId" `
                -var "temp_resource_group_name=$TempResourceGroupName" `
                -var "tenant_id=$TenantId" `
                -var "virtual_network_name=$VirtualNetworkName" `
                -var "virtual_network_resource_group_name=$VirtualNetworkRG" `
                -var "virtual_network_subnet_name=$VirtualNetworkSubnet" `
                -var "run_validation_diskspace=$env:RUN_VALIDATION_FLAG" `
                -var "managed_image_name=$ImageType-$ResourcesNamePrefix" `
                -var "managed_image_resource_group_name=$ResourceGroup" `
                -color=false `
                $TemplatePath `
        | Foreach-Object { 
            $currentString = $_
            if ($currentString -match '(OSDiskUri|OSDiskUriReadOnlySas|TemplateUri|TemplateUriReadOnlySas|AMI|ManagedImageId|ManagedImageName|ManagedImageResourceGroupName|ManagedImageLocation|ManagedImageSharedImageGalleryId): (.*)') {
                $varName = $Matches[1]
                $varValue = $Matches[2]
                Write-Host "##vso[task.setvariable variable=$varName;isOutput=true;]$varValue"
            }
            Write-Output $_ 
        } | Where-Object {
            #Filter sensitive data from Packer logs
            $currentString = $_

            $sensitiveString = $SensitiveData | Where-Object { $currentString -match $_ }
            $sensitiveString -eq $null
        }