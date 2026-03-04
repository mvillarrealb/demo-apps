@description('Azure region for resources')
param location string = resourceGroup().location

@description('App Service Plan name (from naming convention)')
param appServicePlanName string

@description('Web App name (from naming convention)')
param webAppName string

@description('Web App configuration object')
param webAppConfig object

@description('Storage Account name')
param storageAccountName string

@description('Storage Account access key')
@secure()
param storageAccountKey string

@description('Storage container name')
param storageContainerName string

@description('Common tags to apply to all resources')
param commonTags object

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: webAppConfig.appServicePlan.sku
    tier: startsWith(webAppConfig.appServicePlan.sku, 'B') ? 'Basic' : startsWith(webAppConfig.appServicePlan.sku, 'S') ? 'Standard' : 'Premium'
    size: webAppConfig.appServicePlan.sku
    family: substring(webAppConfig.appServicePlan.sku, 0, 1)
    capacity: 1
  }
  properties: {
    reserved: webAppConfig.appServicePlan.reserved
  }
  kind: webAppConfig.appServicePlan.kind
  tags: commonTags
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: webAppConfig.webApp.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: webAppConfig.appServicePlan.reserved
    httpsOnly: webAppConfig.webApp.httpsOnly
    clientAffinityEnabled: webAppConfig.webApp.clientAffinityEnabled
    siteConfig: {
      http20Enabled: webAppConfig.webApp.http20Enabled
      linuxFxVersion: webAppConfig.webApp.linuxFxVersion
      appSettings: [
        {
          name: 'NODE_ENV'
          value: webAppConfig.webApp.nodeEnv
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: webAppConfig.webApp.nodeVersion
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'STORAGE_ACCOUNT_KEY'
          value: storageAccountKey
        }
        {
          name: 'STORAGE_CONTAINER_NAME'
          value: storageContainerName
        }
      ]
    }
  }
  tags: commonTags
}

// Outputs
@description('App Service Plan name')
output appServicePlanName string = appServicePlan.name

@description('Web App name')
output webAppName string = webApp.name

@description('Web App URL')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('Web App default host name')
output webAppDefaultHostName string = webApp.properties.defaultHostName

@description('Web App Managed Identity Principal ID')
output webAppManagedIdentityPrincipalId string = webApp.identity.principalId
