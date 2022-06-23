function Deploy-StorageAccountAsApprovedByCompanyInfrastructureSecurity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ProjectName
    )

    $approvedLocations = 'switzerlandnorth', 'westeurope'

    $storageAccounts = @{}

    foreach ($approvedLocation in $approvedLocations) {
        $resourceGroup = New-AzureNativeResourcesResourceGroup -pulumiid "$ProjectName-$approvedLocation" -resourceGroupName "$ProjectName-$approvedLocation" -location $approvedLocation

        $Props = @{
            pulumiid          = "sa-$approvedLocation"
            accountName       = "$($ProjectName)sa".ToLower()
            ResourceGroupName = $resourceGroup.reference("name")
            location          = $approvedLocation
            Kind              = "StorageV2"
            Sku               = @{
                Name = "Standard_LRS"
            }
        }
        $storageAccounts[$approvedLocation] = @{
            StorageAccount = New-AzureNativeStorageStorageAccount @Props
            ResourceGroup  = $resourceGroup
        }
    }

    return $storageAccounts
}
