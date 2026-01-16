using '../main.bicep'

// ===================================
// GENERAL CONFIGURATION - PRODUCTION
// ===================================
param projectName = 'gastos'
param environment = 'prod'
param location = 'East US 2'
param existingResourceGroupName = 'rgprod-workshop-bicep'

// ===================================
// STORAGE CONFIGURATION - PRODUCTION
// ===================================
param storageAccountSku = 'Standard_GRS'          // Geo-redundant for production
param storageAccessTier = 'Hot'                   // Hot tier for frequent access
param allowBlobPublicAccess = false               // Enhanced security for production

// ===================================
// SQL DATABASE CONFIGURATION - PRODUCTION
// ===================================
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = ''                   // Will be prompted securely during deployment
param sqlDatabaseEdition = 'Standard'             // Better performance for production
param sqlDatabaseCollation = 'SQL_Latin1_General_CP1_CI_AS'

// ===================================
// WEB APP CONFIGURATION - PRODUCTION
// ===================================
param appServiceSku = 'S1'                        // Standard tier for production (1 vCPU, 1.75GB RAM)
param nodeJsVersion = '18-lts'                    // Stable LTS version
param nodeEnvironment = 'production'              // Production optimizations

// ===================================
// KEY VAULT CONFIGURATION - PRODUCTION
// ===================================
param keyVaultSku = 'standard'
param softDeleteRetentionInDays = 90              // Extended retention for production
param enablePurgeProtection = true                // Prevent accidental permanent deletion
param keyVaultPublicNetworkAccess = 'Enabled'     // Can be restricted later if needed

// ===================================
// PRODUCTION-SPECIFIC NOTES
// ===================================
// 
// 1. RESOURCE GROUP: Create manually before deployment:
//    az group create --name "rgprod-workshop-bicep" --location "East US 2"
//
// 2. MONITORING: Consider adding Application Insights for production monitoring
//
// 3. BACKUP: SQL Database backups are automatic with Standard edition
//
// 4. SCALING: S1 App Service can auto-scale if needed
//
// 5. SECURITY: Review firewall rules and consider private endpoints for enhanced security
//
