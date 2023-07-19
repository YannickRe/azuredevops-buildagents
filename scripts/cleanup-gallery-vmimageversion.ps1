
param(
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroup
)

# Variables
$imageDefinitions = @(
    "ubuntu2004-agentpool-full",
    "ubuntu2204-agentpool-full",
    "windows2019-agentpool-full",
    "windows2022-agentpool-full"
)

# install required modules
install-module Az.Compute -Scope CurrentUser -AllowClobber -Force
import-module Az.Compute

# Login using service principal
$securePassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$credentials = New-Object -TypeName PSCredential -ArgumentList $ClientId, $securePassword
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $credentials -Subscription $SubscriptionId
Set-AzureSubscription -SubscriptionId $SubscriptionId

# Set the image threshold
# Threshhold value 3 will remove the oldest vm images if there 3 or more images available in the gallery. This value can be changed to your needs.
$imageCountThreshold = 3

# Get the gallery
try {
    $gallery = Get-AzGallery -Name $GalleryName -ResourceGroupName $ResourceGroup 
    }
catch  {
    Write-Host "##vso[task.logissue type=error;] Gallery '$GalleryName' not found"
    Write-Host "##vso[task.complete result=Failed;]Task failed!"
    exit 0

}


if ($gallery) {
    # Loop through the image definitions
    foreach ($imageDefinition in $imageDefinitions) {
        # Get the image definition
        try {
        $imageDef = Get-AzGalleryImageDefinition  -ResourceGroupName $ResourceGroup -GalleryName $gallery.Name  -GalleryImageDefinitionName $imageDefinition
            }
        catch {
            Write-Host "##vso[task.logissue type=error;] Imagedefinition '$imageDefinition' not found"
            Write-Host "##vso[task.complete result=Failed;]Task failed!"
            exit 0
        }
                
        if ($imageDef) {
            # Get all images of the image definition
            $images = Get-AzGalleryImageVersion -ResourceGroupName $ResourceGroup -GalleryImageDefinitionName $imageDef.Name  -GalleryName $gallery.Name
               
            if ($images.Count -ge $imageCountThreshold) {
                # Sort the images by creation timestamp in ascending order
                $sortedImages = $images | Sort-Object -Property CreatedTime

                # Remove the oldest image
                $imageToRemove = $sortedImages[0]

                Write-Host "##[section]Removing the oldest image version for image definition '$imageDefinition': $($imageToRemove.Name)"
                Remove-AzGalleryImageVersion -ResourceGroupName $ResourceGroup -GalleryName $gallery.Name -GalleryImageDefinitionName $imageDefinition -Name $imageToRemove.Name -Force -AsJob 
            } else {
                Write-Host "##[section]The number of images for image definition '$imageDefinition' is less than $imageCountThreshold"
            }
        }
   }
} 

# Timeout of 10 minutes
Write-Host "##[section]Timeout: 10 minutes. Required to keep connection open to finalize the image removal jobs."
Start-Sleep -Seconds 600