@description('Azure region for resources')
param location string = resourceGroup().location

@description('Key Vault name (from naming convention)')
param keyVaultName string

@description('Tenant ID for Key Vault access')
param tenantId string

@description('Common tags to apply to all resources')
param commonTags object

@description('Key Vault configuration object')
param keyVaultConfig object

@description('SQL Server administrator password (to be stored as secret)')
@secure()
param sqlAdminPassword string

@description('SQL Server FQDN for connection string')
param sqlServerFqdn string

@description('SQL Database name for connection string')
param sqlDatabaseName string

@description('SQL Admin login for connection string')
param sqlAdminLogin string

@description('Web App Managed Identity Principal ID for access policy')
param webAppManagedIdentityPrincipalId string

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: keyVaultConfig.sku
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: keyVaultConfig.enabledForTemplateDeployment
    enableSoftDelete: keyVaultConfig.enableSoftDelete
    softDeleteRetentionInDays: keyVaultConfig.softDeleteRetentionInDays
    enablePurgeProtection: keyVaultConfig.enablePurgeProtection
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: webAppManagedIdentityPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: keyVaultConfig.publicNetworkAccess
  }
  tags: commonTags
}

// SQL Admin Password Secret
resource sqlAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'SqlAdminPassword'
  properties: {
    value: sqlAdminPassword
    attributes: {
      enabled: true
    }
  }
}

// Database Connection String Secret
resource databaseConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'DatabaseConnectionString'
  properties: {
    value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    attributes: {
      enabled: true
    }
  }
}

// Outputs
@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault ID')
output keyVaultId string = keyVault.id

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault resource for access policy configuration')
output keyVaultResource object = keyVault

@description('SQL Admin Password secret URI')
output sqlAdminPasswordSecretUri string = sqlAdminPasswordSecret.properties.secretUri

@description('Database Connection String secret URI')
output databaseConnectionStringSecretUri string = databaseConnectionStringSecret.properties.secretUri
