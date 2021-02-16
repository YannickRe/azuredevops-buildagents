# DevOps Build Agents
This project generates self-hosted build agents based on the [official Microsoft-hosted build agents images](https://github.com/actions/virtual-environments), in an Aure DevOps Pipeline. The resulting Azure Managed Image will be associated to the existing Virtual Machine Scale Set so that new VM's will be using the newly generated image.  This Virtual Machine Scale Set is managed by Azure DevOps as a [Azure Virtual Machine Scale Set Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser&WT.mc_id=M365-MVP-5003400#azure-virtual-machine-scale-set-agents).

Currently supports Windows Server 2019 and Ubuntu 2004 images.

## Available pipelines
- __[buildagent-generation.yml](./buildagent-generation.yml)__  
  - Checkout the latest `main` branch from [actions/virtual-environments](https://github.com/actions/virtual-environments)
  - Build the VM with Packer  
  - Clean up remaining temporary Azure resources  
  - Turn VM disk into Azure Managed Image  
  - Update Virtual Machine Scale Set with new Managed Image  
- __[managedimage-cleanup.yml](./managedimage-cleanup.yml)__  
  - Remove unused Azure Managed Images

## Preparation
The pipeline requires Azure resources for the temporary building of the VM image, Azure resources for running the resulting Agent Pool, and some configuration in Azure DevOps.

### Azure Resources for Packer execution
The Azure resources are created with the [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?WT.mc_id=M365-MVP-5003400)  

1. Connect to Azure
```
Connect-AzAccount -UseDeviceAuthentication
```
2. Create resource group that will store the Packer temporary resources
```
New-AzResourceGroup -Name "DevOps-PackerResources" -Location "West Europe"
```
3. Create an Azure Storage Account to store the generated VHD
```
New-AzStorageAccount -ResourceGroupName "DevOps-PackerResources" -AccountName "devopspacker" -Location "West Europe" -SkuName "Standard_LRS"
```
4. Create Azure AD Service Principal, output client secret and client id
```
$sp = New-AzADServicePrincipal -DisplayName "DevOps-Packer"
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$plainPassword
$sp.ApplicationId
```
5. Make the Service Principal a Contributor on the subscription
```
New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
```
6. Make the Service Principal a Storage Blob Data Contributor on the subscription
```
New-AzRoleAssignment -RoleDefinitionName "Storage Blob Data Contributor" -ServicePrincipalName $sp.ApplicationId
```

### GitHub Token
Generate a GitHub Personal Access Token that allows Packer to download Packages from GitHub.
- Go to [github.com](https://github.com) and log in  
- Click on your profile image to fold out the menu, and select `Settings`  
- On the Settings page, select `Developer settings` from the menu
- On the  Developer settings page, select `Personal access tokens` from the menu  
- Click `Generate` to create a new token.
- Give it a name and make sure you select at least `read:packages` underneath `scopes`

Keep the generated token safe, for usage later in this guide.

### Azure Virtual Machine Scale Set
To use an Azure Virtual Machine Scale Set as an Azure DevOps Scale Set Agent it has to adhere to a certain set of requirements. [The documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops&WT.mc_id=M365-MVP-5003400#create-the-scale-set) contains all the required information, but at the time of writing the following things were important:
- __VM size__: at least *Standard_D4s_v4*
- __Overprovisioning__: *no*, Azure DevOps will decide whether or not new VM's (and thus Agents) need to be provisioned
- __Upgrade policy__: *manual*

### Azure DevOps Scale Set Agent
The Virtual Machine Scale Set from the previous step needs to be registered as an Agent Pool in Azure DevOps. [The instructions are very clear](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops&WT.mc_id=M365-MVP-5003400#create-the-scale-set-agent-pool):
- Add an Agent Pool of type "Azure virtual machine scale set"  
- Use a service connection to select the scale set from the previous step (only supported via `Secret` authentication, not `Certificate` or `Managed Identity` authentication)  
- Give the agent pool a name  
- Enter the required configuration values  

### Azure DevOps Variable Group
Create a Variable Group in the Azure DevOps project running the pipeline, and give it a name. It needs to contain the following variables with their appropriate value:
| Variable  | Description |
|---|---|
| AZURE_AGENTS_RESOURCE_GROUP | Resource Group that contains the Virtual Machine Scale Sets to be used as Scale Set Agents in Azure DevOps |
| AZURE_LOCATION | Azure location where Packer will create the temporary resources |
| AZURE_RESOURCE_GROUP | Resource group containing the Azure Storage Account that will be used by Packer. The resulting Azure Managed Image will also be put in this Resource Group |
| AZURE_STORAGE_ACCOUNT | Storage Account that Packer will use to store the temporary OSDisk and the resulting sysprepped .vhd |
| AZURE_SUBSCRIPTION | Subscription ID of the Azure Subscription that is used to host the temporary resources. |
| AZURE_TENANT | Tenant ID of the Azure tenant that has the Azure Resource Groups and Subscription. |
| CLIENT_ID | Id of the Azure AD application that has appriopriate permissions on the Subscription to create temporary resources and finalizing the Scale Set configuration. See output from scripts above. |
| CLIENT_SECRET | Application secret to be used fot the connection in combination with the Client Id. See output from scripts above. |
| GITHUB_TOKEN | A `Personal access token` for GitHub to fetch packages, having at least the `read:packages` scope. |
| VMSS_Windows2019 | Name of the Azure Virtual Machine Scale Set that will run Build Agents on Windows Server 2019 |
| VMSS_Ubuntu2004 | Name of the Azure Virtual Machine Scale Set that will run Build Agents on Ubuntu 20.04 |

## Pipeline runtime parameters
### Build Agent Generation
![Runtime parameters for Build Agent Generation](./assets/BuildAgentGeneration-Queue.png)  

- __Build Agent Image__: which image to build, choice between `Windows Server 2019` and `Ubuntu 20.04`  
- __Variable Group__: name of the Variable Group containing the variables necessary for execution
- __Agent Pool__: the Agent Pool to use for running the pipeline

### Managed Image Cleanup
![Runtime parameters for Managed Images Cleanup](./assets/ManagedImageCleanup-Queue.png)

- __Variable Group__: name of the Variable Group containing the variables necessary for execution

## Good to know
### Packer
[Packer](https://www.packer.io/) is an open source tool for creating identical machine images for multiple platforms from a single source configuration. Important to know: while building the image, Packer will spin up a VM in Azure to run the installation instructions, sys-prep that image after completion and cleanup all the temporary resources.

### Scale Set Agents
Azure virtual machine scale set agents are a form of self-hosted agents that can be autoscaled to meet demands. This elasticity reduces the need to run dedicated agents all the time.

### Pipeline runtime
Generating the images takes a long time, so don't be surprised. A Windows Server 2019 image takes about 6 to 7h's to generate, a Ubuntu 20.04 image takes about 4h's.

### Chicken or the egg
Generating the image through Packer takes longer than 1h (see previous bullet point), and thus can't be run on the free tier of the Microsoft Hosted Agents (limited to 1h runs). It can only be run on the paid tier of the Microsoft Hosted Agent, or it needs an existing self-hosted agent to run.  
In this project, the initial run of the project is done on a paid Microsoft Hosted Agent and then switched over to the newly generated self-hosted agent scale set.

### Lingering temporary resources
All temporary resources that Packer create on Azure should be deleted when Packer finishes exection, only leaving the final sysprepped .vhd in the Storage Account.  
The current version of Packer (1.6.6) fails to delete the .vhd of the temporary VM, this is a [known issue and supposedly on track to be resolved in version 1.7.0 of Packer](https://github.com/hashicorp/packer/issues/10416).

## Agent Pool Usage
See documentation for [YAML-based pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2cbrowser&WT.mc_id=M365-MVP-5003400#choosing-a-pool-and-agent-in-your-pipeline) and [Classic pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=classic%2cbrowser&WT.mc_id=M365-MVP-5003400#choosing-a-pool-and-agent-in-your-pipeline)
