using '../main.bicep'

// ===================================
// GENERAL CONFIGURATION
// ===================================
param projectName = 'appexp'
param environment = 'dev'
param location = 'Canada Central'
param existingResourceGroupName = 'rgdev-workshop-bicep'

// ===================================
// STORAGE CONFIGURATION
// ===================================
param storageAccountSku = 'Standard_LRS'
param storageAccessTier = 'Hot'
param allowBlobPublicAccess = true

// ===================================
// SQL DATABASE CONFIGURATION
// ===================================
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = ''  
param sqlDatabaseEdition = 'Basic'
param sqlDatabaseCollation = 'SQL_Latin1_General_CP1_CI_AS'

// ===================================
// WEB APP CONFIGURATION
// ===================================
param appServiceSku = 'B1'
param nodeJsVersion = '18-lts'
param nodeEnvironment = 'development'

// ===================================
// KEY VAULT CONFIGURATION
// ===================================
param keyVaultSku = 'standard'
param softDeleteRetentionInDays = 7
param enablePurgeProtection = true
param keyVaultPublicNetworkAccess = 'Enabled'
