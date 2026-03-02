@description('Web App name')
param webAppName string

@description('Web App configuration object')
param webAppConfig object

@description('Database Connection String secret URI from Key Vault')
param databaseConnectionStringSecretUri string

@description('Storage Account name')
param storageAccountName string

@description('Storage Account access key')
@secure()
param storageAccountKey string

@description('Storage container name')
param storageContainerName string

// Reference to existing Web App
resource existingWebApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: webAppName
}

// Update Web App configuration with Key Vault references
resource webAppAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: existingWebApp
  name: 'appsettings'
  properties: {
    NODE_ENV: webAppConfig.webApp.nodeEnv
    WEBSITE_NODE_DEFAULT_VERSION: webAppConfig.webApp.nodeVersion
    DATABASE_URL: '@Microsoft.KeyVault(SecretUri=${databaseConnectionStringSecretUri})'
    STORAGE_ACCOUNT_NAME: storageAccountName
    STORAGE_ACCOUNT_KEY: storageAccountKey
    STORAGE_CONTAINER_NAME: storageContainerName
  }
}

// Outputs
@description('App settings update completed')
output appSettingsUpdated bool = true
