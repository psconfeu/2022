Import-Module pspulumiyaml.azurenative.resources
Import-Module pspulumiyaml.azurenative.storage

New-PulumiYamlFile {

    $location = 'switzerlandnorth', 'westeurope'

    $resourceGroup = New-AzureNativeResourcesResourceGroup -pulumiid "static-web-app" -resourceGroupName "ps-static-web-app" -location $location[0]

    $Props = @{
        pulumiid          = "sa"
        accountName       = "rbpspulumistweb"
        ResourceGroupName = $resourceGroup.reference("name")
        location          = $location[0]
        Kind              = "StorageV2"
        Sku               = @{
            Name = "Standard_LRS"
        }
    }
    $storageAccount = New-AzureNativeStorageStorageAccount @Props

    $Props = @{
        pulumiid          = "website"
        accountName       = $storageAccount.reference("name")
        resourceGroupName = $resourceGroup.reference("name")
        indexDocument     = "index.html"
        error404Document  = "404.html"
    }
    $website = New-AzureNativeStorageStorageAccountStaticWebsite @Props

    @(
        @{
            Name = "index.html"
            Type = "text/html"
        },
        @{
            Name = "404.html"
            Type = "text/html"
        },
        @{
            Name = "favicon.png"
            Type = "image/png"
        }
    ) | ForEach-Object {
        $Props = @{
            pulumiid          = $_.Name
            ResourceGroupName = $resourceGroup.reference("name")
            AccountName       = $storageAccount.reference("name")
            ContainerName     = $website.reference("containerName")
            contentType       = $_.Type
            Type              = "Block"
            Source            = New-PulumiFileAsset "./www/$($_.Name)"
        }
        $null = New-AzureNativeStorageBlob @Props
    }

    $keys = Invoke-AzureNativeFunctionStorageListStorageAccountKeys -accountName $storageAccount.reference("name") -resourceGroupName $resourceGroup.reference("name")

    New-PulumiOutput -Name test -Value $storageAccount.reference("primaryEndpoints.web")
    New-PulumiOutput -Name primarykey -Value $keys.reference("keys[0].value")
}
