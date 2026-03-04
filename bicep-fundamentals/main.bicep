// ===================================
// GENERAL CONFIGURATION PARAMETERS
// ===================================

@description('Name of the project')
param projectName string

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region for resources')
param location string

@description('Name of the existing Resource Group')
param existingResourceGroupName string

// ===================================
// STORAGE CONFIGURATION PARAMETERS
// ===================================

@description('Storage Account SKU')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS'])
param storageAccountSku string

@description('Storage Account access tier')
@allowed(['Hot', 'Cool'])
param storageAccessTier string

@description('Allow blob public access')
param allowBlobPublicAccess bool

// ===================================
// SQL DATABASE CONFIGURATION PARAMETERS
// ===================================

@description('SQL Server administrator login')
param sqlAdminLogin string

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

@description('SQL Database edition')
@allowed(['Basic', 'Standard', 'Premium'])
param sqlDatabaseEdition string

@description('SQL Database collation')
param sqlDatabaseCollation string

// ===================================
// WEB APP CONFIGURATION PARAMETERS
// ===================================

@description('App Service Plan SKU')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1', 'P2', 'P3'])
param appServiceSku string

@description('Node.js version for the Web App')
@allowed(['16-lts', '18-lts', '20-lts'])
param nodeJsVersion string

@description('Node.js environment')
@allowed(['development', 'production'])
param nodeEnvironment string

// ===================================
// KEY VAULT CONFIGURATION PARAMETERS
// ===================================

@description('Key Vault SKU')
@allowed(['standard', 'premium'])
param keyVaultSku string

@description('Soft delete retention in days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int

@description('Enable purge protection')
param enablePurgeProtection bool

@description('Public network access for Key Vault')
@allowed(['Enabled', 'Disabled'])
param keyVaultPublicNetworkAccess string

// ===================================
// RESOURCE REFERENCES
// ===================================

// Reference to existing Resource Group
resource existingResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: existingResourceGroupName
  scope: subscription()
}

// ===================================
// VARIABLES - CENTRALIZED CONFIGURATION
// ===================================

// Unique suffix for resource naming
var uniqueSuffix = substring(uniqueString(existingResourceGroup.id), 0, 6)

// ===================================
// NAMING CONVENTION VARIABLES
// ===================================

var naming = {
  storageAccount: 'st${toLower(projectName)}${toLower(environment)}${uniqueSuffix}'
  sqlServer: 'sql-${toLower(projectName)}-${toLower(environment)}-${uniqueSuffix}'
  sqlDatabase: 'sqldb-${toLower(projectName)}-${toLower(environment)}'
  appServicePlan: 'plan-${toLower(projectName)}-${toLower(environment)}-${uniqueSuffix}'
  webApp: 'webapp-${toLower(projectName)}-${toLower(environment)}-${uniqueSuffix}'
  keyVault: 'kv-${toLower(projectName)}-${toLower(environment)}-${uniqueSuffix}'
  containerName: 'assets'
}

// ===================================
// COMMON TAGS CONFIGURATION
// ===================================

var commonTags = {
  project: projectName
  environment: environment
  managedBy: 'bicep'
  deployedAt: '2026-01-16'
}

// ===================================
// STORAGE CONFIGURATION OBJECT
// ===================================

var storageConfig = {
  sku: storageAccountSku
  kind: 'StorageV2'
  accessTier: storageAccessTier
  minimumTlsVersion: 'TLS1_2'
  supportsHttpsTrafficOnly: true
  allowBlobPublicAccess: allowBlobPublicAccess
  publicNetworkAccess: 'Enabled'
}

// ===================================
// SQL DATABASE CONFIGURATION OBJECT
// ===================================

var sqlConfig = {
  serverVersion: '12.0'
  minimalTlsVersion: '1.2'
  publicNetworkAccess: 'Enabled'
  database: {
    edition: sqlDatabaseEdition
    collation: sqlDatabaseCollation
    zoneRedundant: false
  }
}

// ===================================
// WEB APP CONFIGURATION OBJECT
// ===================================

var webAppConfig = {
  appServicePlan: {
    sku: appServiceSku
    kind: 'linux'
    reserved: true
  }
  webApp: {
    kind: 'app,linux'
    httpsOnly: true
    clientAffinityEnabled: false
    http20Enabled: true
    linuxFxVersion: 'NODE|${nodeJsVersion}'
    nodeEnv: nodeEnvironment
    nodeVersion: nodeJsVersion
  }
}

// ===================================
// KEY VAULT CONFIGURATION OBJECT
// ===================================

var keyVaultConfig = {
  sku: keyVaultSku
  softDeleteRetentionInDays: softDeleteRetentionInDays
  enablePurgeProtection: enablePurgeProtection
  publicNetworkAccess: keyVaultPublicNetworkAccess
  enabledForTemplateDeployment: true
  enableSoftDelete: true
}

// ===================================
// MODULES - INFRASTRUCTURE DEPLOYMENT
// ===================================

// Storage Account Module
module storageModule 'modules/storage.bicep' = {
  name: 'storage-${projectName}-${environment}-${uniqueSuffix}'
  scope: existingResourceGroup
  params: {
    location: location
    storageAccountName: naming.storageAccount
    containerName: naming.containerName
    storageConfig: storageConfig
    commonTags: commonTags
  }
}

// SQL Server and Database Module
module sqlModule 'modules/sql.bicep' = {
  name: 'sql-${projectName}-${environment}-${uniqueSuffix}'
  scope: existingResourceGroup
  params: {
    location: location
    sqlServerName: naming.sqlServer
    sqlDatabaseName: naming.sqlDatabase
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    sqlConfig: sqlConfig
    commonTags: commonTags
  }
}

// Web App Module
module webAppModule 'modules/webapp.bicep' = {
  name: 'webapp-${projectName}-${environment}-${uniqueSuffix}'
  scope: existingResourceGroup
  params: {
    location: location
    appServicePlanName: naming.appServicePlan
    webAppName: naming.webApp
    webAppConfig: webAppConfig
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountAccessKeys.key1
    storageContainerName: storageModule.outputs.assetsContainerName
    commonTags: commonTags
  }
}

// Key Vault Module (after Web App to get Managed Identity Principal ID)
module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyvault-${projectName}-${environment}-${uniqueSuffix}'
  scope: existingResourceGroup
  params: {
    location: location
    keyVaultName: naming.keyVault
    tenantId: tenant().tenantId
    commonTags: commonTags
    keyVaultConfig: keyVaultConfig
    sqlAdminPassword: sqlAdminPassword
    sqlServerFqdn: sqlModule.outputs.sqlServerFqdn
    sqlDatabaseName: sqlModule.outputs.sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    webAppManagedIdentityPrincipalId: webAppModule.outputs.webAppManagedIdentityPrincipalId
  }
}

// Web App Configuration Update (after Key Vault to get secret URIs)
module webAppConfigModule 'modules/webapp-config.bicep' = {
  name: 'webappconfig-${projectName}-${environment}-${uniqueSuffix}'
  scope: existingResourceGroup
  params: {
    webAppName: webAppModule.outputs.webAppName
    webAppConfig: webAppConfig
    databaseConnectionStringSecretUri: keyVaultModule.outputs.databaseConnectionStringSecretUri
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountAccessKeys.key1
    storageContainerName: storageModule.outputs.assetsContainerName
  }
}

// ===================================
// OUTPUTS - ORGANIZED BY FUNCTIONALITY
// ===================================

// ===================================
// INFRASTRUCTURE OUTPUTS
// ===================================

@description('Resource Group name')
output resourceGroupName string = existingResourceGroup.name

@description('Azure region where resources are deployed')
output deploymentLocation string = location

@description('Project name')
output projectName string = projectName

@description('Environment name')
output environment string = environment

// ===================================
// STORAGE OUTPUTS
// ===================================

@description('Storage Account name')
output storageAccountName string = storageModule.outputs.storageAccountName

@description('Storage Account ID')
output storageAccountId string = storageModule.outputs.storageAccountId

@description('Storage Account primary blob endpoint')
output storageAccountPrimaryEndpoint string = storageModule.outputs.storageAccountPrimaryEndpoint

@description('Storage Account access keys')
@secure()
output storageAccountAccessKeys object = storageModule.outputs.storageAccountAccessKeys

@description('Assets container name')
output assetsContainerName string = storageModule.outputs.assetsContainerName

// ===================================
// KEY VAULT OUTPUTS
// ===================================

@description('Key Vault name')
output keyVaultName string = keyVaultModule.outputs.keyVaultName

@description('Key Vault URI')
output keyVaultUri string = keyVaultModule.outputs.keyVaultUri

@description('SQL Admin Password secret URI (for Key Vault references)')
output sqlAdminPasswordSecretUri string = keyVaultModule.outputs.sqlAdminPasswordSecretUri

@description('Database Connection String secret URI (for Key Vault references)')
output databaseConnectionStringSecretUri string = keyVaultModule.outputs.databaseConnectionStringSecretUri

// ===================================
// DATABASE OUTPUTS
// ===================================

@description('SQL Server name')
output sqlServerName string = sqlModule.outputs.sqlServerName

@description('SQL Server fully qualified domain name')
output sqlServerFqdn string = sqlModule.outputs.sqlServerFqdn

@description('SQL Database name')
output sqlDatabaseName string = sqlModule.outputs.sqlDatabaseName

@description('SQL Connection String (without password)')
output sqlConnectionString string = sqlModule.outputs.sqlConnectionString

// ===================================
// WEB APPLICATION OUTPUTS
// ===================================

@description('App Service Plan name')
output appServicePlanName string = webAppModule.outputs.appServicePlanName

@description('Web App name')
output webAppName string = webAppModule.outputs.webAppName

@description('Web App primary URL')
output webAppUrl string = webAppModule.outputs.webAppUrl

@description('Web App default hostname')
output webAppDefaultHostName string = webAppModule.outputs.webAppDefaultHostName

@description('Web App Managed Identity Principal ID')
output webAppManagedIdentityPrincipalId string = webAppModule.outputs.webAppManagedIdentityPrincipalId

@description('Web App configuration updated with Key Vault references')
output webAppSecurelyConfigured bool = webAppConfigModule.outputs.appSettingsUpdated
