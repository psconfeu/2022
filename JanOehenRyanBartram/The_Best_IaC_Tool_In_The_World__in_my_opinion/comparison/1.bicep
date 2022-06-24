targetScope = 'subscription'

param location string = deployment().location

param deploymentScriptTimestamp string = utcNow()

var resourceGroupName = 'bicep-static-web-app'

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module stgModule './2.bicep' = {
  name: 'storageWebDeploy-${deploymentScriptTimestamp}'
  scope: newRG
  params: {
    skuName: 'Standard_LRS'
    location: location
    accountName: 'rbbicepstweb'
  }
}

output test string = stgModule.outputs.test
output primarykey string = stgModule.outputs.primarykey
