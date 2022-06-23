targetScope = 'resourceGroup'

param location string
param accountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param skuName string

param deploymentScriptTimestamp string = utcNow()
param indexDocument string = 'index.html'
param errorDocument404Path string = '404.html'

var storageAccountContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab') // This is the Storage Account Contributor role, which is the minimum role permission we can give. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=17d1049b-9a84-46fb-8f53-869881c3d3ab
var storageBlobDataContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // This is the Storage Blob Data Contributor role, which is the minimum role permission we can give. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=17d1049b-9a84-46fb-8f53-869881c3d3ab

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: accountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {}
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'DeploymentScriptMSIBicep'
  location: location
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(resourceGroup().id, storageAccountContributorRoleDefinitionId)
  properties: {
    roleDefinitionId: storageAccountContributorRoleDefinitionId
    principalId: managedIdentity.properties.principalId
  }
}

resource dataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(resourceGroup().id, storageBlobDataContributorRoleDefinitionId)
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinitionId
    principalId: managedIdentity.properties.principalId
  }
}

resource deploymentScriptPwsh 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScriptPwsh'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    contributorRoleAssignment
    storageAccount
  ]
  properties: {
    azPowerShellVersion: '3.0'
    scriptContent: '''
param(
    [string] $ResourceGroupName,
    [string] $StorageAccountName,
    [string] $IndexDocument,
    [string] $ErrorDocument404Path)

$ErrorActionPreference = 'Stop'
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName

$ctx = $storageAccount.Context
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocument -ErrorDocument404Path $ErrorDocument404Path
'''
    forceUpdateTag: deploymentScriptTimestamp
    retentionInterval: 'PT4H'
    arguments: '-ResourceGroupName ${resourceGroup().name} -StorageAccountName ${accountName} -IndexDocument ${indexDocument} -ErrorDocument404Path ${errorDocument404Path}'
  }
}

resource deploymentScriptAzCli 'Microsoft.Resources/deploymentScripts@2020-10-01' = [for fileinfo in [
  {
    content: loadTextContent('./www/index.html')
    name: 'index.html'
    type: 'text/html'
  }
  {
    content: loadTextContent('./www/404.html')
    name: '404.html'
    type: 'text/html'
  }
] : {
  name: 'deployscript-upload-blob-${fileinfo.name}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    dataContributorRoleAssignment
  ]
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTAINER'
        secureValue: '$web'
      }
      {
        name: 'CONTENT'
        value: fileinfo.content
      }
      {
        name: 'NAME'
        value: fileinfo.name
      }
      {
        name: 'TYPE'
        value: fileinfo.type
      }
    ]
    forceUpdateTag: deploymentScriptTimestamp
    scriptContent: 'echo "$CONTENT" > $NAME && az storage blob upload -f $NAME -c $CONTAINER -n $NAME --content-type $TYPE'
  }
}]

output test string = storageAccount.properties.primaryEndpoints.web
output primarykey string = storageAccount.listKeys().keys[0].value
