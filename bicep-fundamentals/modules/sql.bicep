@description('Azure region for resources')
param location string = resourceGroup().location

@description('SQL Server name (from naming convention)')
param sqlServerName string

@description('SQL Database name (from naming convention)')
param sqlDatabaseName string

@description('SQL Server administrator login')
param sqlAdminLogin string

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

@description('SQL configuration object')
param sqlConfig object

@description('Common tags to apply to all resources')
param commonTags object

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: sqlConfig.serverVersion
    minimalTlsVersion: sqlConfig.minimalTlsVersion
    publicNetworkAccess: sqlConfig.publicNetworkAccess
  }
  tags: commonTags
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: sqlConfig.database.edition
    tier: sqlConfig.database.edition
  }
  properties: {
    collation: sqlConfig.database.collation
    zoneRedundant: sqlConfig.database.zoneRedundant
  }
  tags: commonTags
}

// Firewall Rule - Allow Azure Services
resource firewallRuleAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Outputs
@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('SQL Connection String (without password)')
output sqlConnectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminLogin};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
