@description('Azure region for resources')
param location string = resourceGroup().location

@description('Storage Account name (from naming convention)')
param storageAccountName string

@description('Container name for assets')
param containerName string

@description('Storage configuration object')
param storageConfig object

@description('Common tags to apply to all resources')
param commonTags object

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageConfig.sku
  }
  kind: storageConfig.kind
  properties: {
    accessTier: storageConfig.accessTier
    minimumTlsVersion: storageConfig.minimumTlsVersion
    supportsHttpsTrafficOnly: storageConfig.supportsHttpsTrafficOnly
    allowBlobPublicAccess: storageConfig.allowBlobPublicAccess
    publicNetworkAccess: storageConfig.publicNetworkAccess
  }
  tags: commonTags
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

// Assets Container
resource assetsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'Blob'
  }
}

// Outputs
@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Storage Account ID')
output storageAccountId string = storageAccount.id

@description('Storage Account primary endpoint')
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Storage Account access keys')
@secure()
output storageAccountAccessKeys object = {
  key1: storageAccount.listKeys().keys[0].value
  key2: storageAccount.listKeys().keys[1].value
}

@description('Assets container name')
output assetsContainerName string = assetsContainer.name
