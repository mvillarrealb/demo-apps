# ===================================
# AZURE INFRASTRUCTURE CLEANUP SCRIPT (PowerShell)
# ===================================
# Safely removes all resources created by the infrastructure deployment
# With multiple confirmation levels and safety checks
#
# Usage: .\cleanup.ps1 [environment] [force]
#   environment: dev|prod (default: dev)
#   force: skip confirmation prompts (use with caution)
#
# Examples:
#   .\cleanup.ps1 dev
#   .\cleanup.ps1 prod  
#   .\cleanup.ps1 dev -Force

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Position = 1)]
    [switch]$Force
)

# ===================================
# SCRIPT CONFIGURATION
# ===================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$UtilsDir = Join-Path $ScriptDir "utils"

# Import common utilities
. (Join-Path $UtilsDir "common.ps1")

# ===================================
# CLEANUP CONFIGURATION
# ===================================

$ParametersDir = Join-Path $ProjectRoot "parameters"
$CleanupTimeout = 1800  # 30 minutes

# ===================================
# SCRIPT VARIABLES
# ===================================

$ParameterFile = ""
$ResourceGroup = ""
$ProjectName = ""
$ResourcesToDelete = @()

# ===================================
# MAIN FUNCTIONS
# ===================================

function Initialize-Cleanup {
    Write-LogStep "Setting up cleanup configuration"
    
    # Validate environment parameter
    if (-not (Test-Environment $Environment)) {
        Write-LogError "Please specify a valid environment: dev or prod"
        exit 1
    }
    
    # Set parameter file path
    $script:ParameterFile = Join-Path $ParametersDir "main.$Environment.bicepparam"
    
    # Validate parameter file exists
    if (-not (Test-FileExists $ParameterFile "Parameter file for $Environment")) {
        exit 1
    }
    
    # Extract configuration from parameter file
    $script:ResourceGroup = Get-ResourceGroupFromParams $ParameterFile
    $script:ProjectName = Get-ProjectNameFromParams $ParameterFile
    
    if ([string]::IsNullOrEmpty($ResourceGroup)) {
        Write-LogError "Could not extract resource group name from parameter file"
        exit 1
    }
    
    if ([string]::IsNullOrEmpty($ProjectName)) {
        Write-LogError "Could not extract project name from parameter file"
        exit 1
    }
    
    Write-LogSuccess "Cleanup configuration set up"
    Write-LogInfo "Environment: $Environment"
    Write-LogInfo "Resource Group: $ResourceGroup"
    Write-LogInfo "Project Name: $ProjectName"
    Write-LogInfo "Parameter File: $ParameterFile"
}

function Test-CleanupPrerequisites {
    Write-LogStep "Validating prerequisites"
    
    # Check Azure CLI and login status
    if (-not (Test-AzureCLI)) {
        exit 1
    }
    
    if (-not (Test-AzureLogin)) {
        exit 1
    }
    
    # Check if resource group exists
    if (-not (Test-ResourceGroupExists $ResourceGroup)) {
        Write-LogWarning "Resource group '$ResourceGroup' does not exist"
        Write-LogInfo "Nothing to clean up"
        exit 0
    }
    
    Write-LogSuccess "Prerequisites validation completed"
}

function Find-ResourcesToDelete {
    Write-LogStep "Analyzing resources to be deleted"
    
    # Get all resources in the resource group that belong to this project
    Write-LogInfo "Searching for project resources..."
    
    try {
        # Try to get resources by tags first
        $allResources = az resource list --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
        $taggedResources = $allResources | Where-Object { 
            $_.tags.project -eq $ProjectName -and $_.tags.environment -eq $Environment 
        }
        
        if ($taggedResources -and $taggedResources.Count -gt 0) {
            Write-LogInfo "Found $($taggedResources.Count) resources with project tags"
            $taggedResources | Format-Table Name, Type, Location -AutoSize
            $script:ResourcesToDelete = $taggedResources
        }
        else {
            Write-LogWarning "No resources found with project tags, analyzing by naming convention..."
            
            # Fallback: get resources by naming convention
            $projectResources = $allResources | Where-Object {
                $_.name -like "*$ProjectName*" -and $_.name -like "*$Environment*"
            }
            
            if ($projectResources -and $projectResources.Count -gt 0) {
                Write-LogInfo "Found $($projectResources.Count) resources matching naming convention"
                $projectResources | Format-Table Name, Type, Location -AutoSize
                $script:ResourcesToDelete = $projectResources
            }
            else {
                Write-LogWarning "No resources found matching project naming convention"
                
                if (-not $Force) {
                    if (Confirm-Action "Show all resources in the resource group for manual selection?") {
                        Show-AllResourcesForSelection
                    }
                    else {
                        Write-LogInfo "Cleanup cancelled by user"
                        exit 0
                    }
                }
                else {
                    Write-LogError "No resources found to delete in force mode"
                    exit 1
                }
            }
        }
        
        # Store resources for deletion
        $ResourcesToDelete | ConvertTo-Json -Depth 10 | Out-File "resources_to_delete.json" -Encoding UTF8
        
        # Check for special resources that need careful handling
        Test-SpecialResources $ResourcesToDelete
    }
    catch {
        Write-LogError "Failed to analyze resources: $($_.Exception.Message)"
        exit 1
    }
}

function Show-AllResourcesForSelection {
    Write-LogInfo "All resources in resource group '$ResourceGroup':"
    
    try {
        $allResources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $allResources | Format-Table Name, Type, Location -AutoSize
        
        Write-Host ""
        Write-LogWarning "⚠️  The above resources will be deleted if you continue"
        Write-LogWarning "⚠️  This includes ALL resources in the resource group, not just project resources"
        
        if (-not $Force) {
            if (-not (Confirm-Action "Are you sure you want to delete ALL resources in this resource group?")) {
                Write-LogInfo "Cleanup cancelled by user"
                exit 0
            }
        }
        
        $script:ResourcesToDelete = $allResources
    }
    catch {
        Write-LogError "Could not list resources in resource group"
        exit 1
    }
}

function Test-SpecialResources {
    param([array]$Resources)
    
    # Check for Key Vaults with purge protection
    $keyVaults = $Resources | Where-Object { $_.type -eq "Microsoft.KeyVault/vaults" }
    
    if ($keyVaults) {
        Write-LogWarning "Found Key Vault(s) that may have purge protection enabled:"
        foreach ($kv in $keyVaults) {
            Write-Host "  • $($kv.name)"
            
            try {
                # Check purge protection status
                $kvDetails = az keyvault show --name $kv.name --output json 2>$null | ConvertFrom-Json
                
                if ($kvDetails.properties.enablePurgeProtection -eq $true) {
                    Write-LogWarning "    ⚠️  Purge protection is ENABLED - vault will be soft deleted"
                    Write-LogInfo "    ℹ️  To permanently delete: az keyvault purge --name $($kv.name) --location $($kv.location)"
                }
            }
            catch {
                Write-LogWarning "    ⚠️  Could not check purge protection status"
            }
        }
    }
    
    # Check for SQL Servers with databases
    $sqlServers = $Resources | Where-Object { $_.type -eq "Microsoft.Sql/servers" }
    
    if ($sqlServers) {
        Write-LogWarning "Found SQL Server(s) with potential data loss:"
        foreach ($server in $sqlServers) {
            Write-Host "  • $($server.name)"
            Write-LogWarning "    ⚠️  All databases and data will be permanently deleted"
        }
    }
    
    # Check for Storage Accounts with data
    $storageAccounts = $Resources | Where-Object { $_.type -eq "Microsoft.Storage/storageAccounts" }
    
    if ($storageAccounts) {
        Write-LogWarning "Found Storage Account(s) with potential data loss:"
        foreach ($storage in $storageAccounts) {
            Write-Host "  • $($storage.name)"
            Write-LogWarning "    ⚠️  All blobs, files, and data will be permanently deleted"
        }
    }
}

function Confirm-Cleanup {
    if ($Force) {
        Write-LogWarning "Running in FORCE MODE - skipping confirmations"
        return
    }
    
    Write-LogStep "Cleanup Confirmation"
    
    # Show summary
    $resourceCount = $ResourcesToDelete.Count
    
    Write-LogWarning "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
    Write-Host ""
    Write-LogInfo "You are about to DELETE the following:"
    Write-LogInfo "  • Environment: $Environment"
    Write-LogInfo "  • Resource Group: $ResourceGroup"
    Write-LogInfo "  • Resources: $resourceCount items"
    Write-LogInfo "  • Project: $ProjectName"
    Write-Host ""
    Write-LogError "🚨 THIS ACTION CANNOT BE UNDONE 🚨"
    Write-LogError "🚨 ALL DATA WILL BE PERMANENTLY LOST 🚨"
    
    Write-Host ""
    
    # First confirmation
    if (-not (Confirm-Action "Do you understand that this will permanently delete all resources and data?")) {
        Write-LogInfo "Cleanup cancelled by user"
        exit 0
    }
    
    # Second confirmation with environment name
    $envConfirmation = Get-UserInput "Type the environment name '$Environment' to confirm deletion"
    
    if ($envConfirmation -ne $Environment) {
        Write-LogError "Environment confirmation failed. Expected: '$Environment', Got: '$envConfirmation'"
        Write-LogInfo "Cleanup cancelled"
        exit 0
    }
    
    # Final confirmation
    if (-not (Confirm-Action "Last chance: Are you absolutely sure you want to proceed with deletion?")) {
        Write-LogInfo "Cleanup cancelled by user"
        exit 0
    }
    
    Write-LogWarning "Cleanup confirmed. Proceeding with deletion..."
}

function Backup-ResourceConfiguration {
    Write-LogStep "Creating backup of resource configurations"
    
    $backupDir = "backup_$($Environment)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    Write-LogInfo "Backing up resource configurations to: $backupDir"
    
    try {
        # Backup resource group information
        az group show --name $ResourceGroup --output json | Out-File (Join-Path $backupDir "resource_group.json") -Encoding UTF8 2>$null
        
        # Backup individual resource configurations
        if (Test-Path "resources_to_delete.json") {
            Copy-Item "resources_to_delete.json" (Join-Path $backupDir "resources_list.json")
            
            foreach ($resource in $ResourcesToDelete) {
                if ($resource.id) {
                    $resourceName = Split-Path $resource.id -Leaf
                    
                    Write-LogInfo "Backing up configuration for: $resourceName"
                    try {
                        az resource show --ids $resource.id --output json | Out-File (Join-Path $backupDir "$resourceName.json") -Encoding UTF8 2>$null
                    }
                    catch {
                        Write-LogWarning "Could not backup configuration for: $resourceName"
                    }
                }
            }
        }
        
        # Backup parameter file
        if (Test-Path $ParameterFile) {
            Copy-Item $ParameterFile (Join-Path $backupDir "parameters.bicepparam")
        }
        
        Write-LogSuccess "Resource configurations backed up to: $backupDir"
        Write-LogInfo "Keep this backup to restore resources if needed"
    }
    catch {
        Write-LogWarning "Some backup operations failed: $($_.Exception.Message)"
    }
}

function Remove-Resources {
    Write-LogStep "Deleting resources"
    
    if (-not (Test-Path "resources_to_delete.json")) {
        Write-LogError "No resources list found"
        exit 1
    }
    
    $resourceCount = $ResourcesToDelete.Count
    
    if ($resourceCount -eq 0) {
        Write-LogInfo "No resources to delete"
        return
    }
    
    Write-LogInfo "Deleting $resourceCount resources..."
    
    # Method 1: Try to delete individual resources first (for better control)
    $deletionErrors = 0
    
    foreach ($resource in $ResourcesToDelete) {
        if ($resource.id) {
            Write-LogInfo "Deleting: $($resource.name) ($($resource.type))"
            
            try {
                az resource delete --ids $resource.id --verbose 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-LogSuccess "  ✅ Deleted: $($resource.name)"
                }
                else {
                    Write-LogWarning "  ⚠️  Failed to delete: $($resource.name) (will retry with resource group deletion)"
                    $deletionErrors++
                }
            }
            catch {
                Write-LogWarning "  ⚠️  Failed to delete: $($resource.name) (will retry with resource group deletion)"
                $deletionErrors++
            }
        }
    }
    
    # Method 2: If individual deletions failed, try resource group deletion
    if ($deletionErrors -gt 0) {
        Write-LogWarning "Some individual resource deletions failed"
        
        if ($Force -or (Confirm-Action "Delete the entire resource group to ensure complete cleanup?")) {
            Remove-ResourceGroup
        }
        else {
            Write-LogWarning "Some resources may remain. Check the resource group manually."
        }
    }
    else {
        Write-LogSuccess "All individual resources deleted successfully"
        
        # Check if resource group is empty and offer to delete it
        try {
            $remainingResources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json
            
            if (-not $remainingResources -or $remainingResources.Count -eq 0) {
                if ($Force -or (Confirm-Action "Resource group is now empty. Delete the resource group as well?")) {
                    Remove-ResourceGroup
                }
            }
            else {
                Write-LogInfo "Resource group contains $($remainingResources.Count) other resources and will be kept"
            }
        }
        catch {
            Write-LogWarning "Could not check remaining resources in resource group"
        }
    }
}

function Remove-ResourceGroup {
    Write-LogInfo "Deleting resource group: $ResourceGroup"
    Write-LogWarning "This will delete ALL resources in the resource group"
    
    try {
        az group delete --name $ResourceGroup --yes --no-wait 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Resource group deletion initiated"
            Write-LogInfo "Deletion is running in the background"
            Write-LogInfo "You can monitor progress with:"
            Write-LogInfo "  az group show --name '$ResourceGroup'"
        }
        else {
            Write-LogError "Failed to initiate resource group deletion"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to initiate resource group deletion: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Test-CleanupCompletion {
    Write-LogStep "Verifying cleanup completion"
    
    # Check if resource group still exists
    try {
        $rgExists = Test-ResourceGroupExists $ResourceGroup 2>$null
        
        if ($rgExists) {
            $remainingResources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json
            
            if (-not $remainingResources -or $remainingResources.Count -eq 0) {
                Write-LogSuccess "✅ Resource group exists but is empty"
            }
            else {
                Write-LogWarning "⚠️  Resource group still contains $($remainingResources.Count) resources"
                Write-LogInfo "Listing remaining resources:"
                $remainingResources | Format-Table Name, Type -AutoSize
            }
        }
        else {
            Write-LogSuccess "✅ Resource group has been completely deleted"
        }
    }
    catch {
        Write-LogWarning "Could not verify cleanup completion"
    }
}

function Remove-TempFiles {
    # Clean up temporary files
    if (Test-Path "resources_to_delete.json") {
        Remove-Item "resources_to_delete.json" -Force 2>$null
    }
}

# ===================================
# MAIN SCRIPT EXECUTION
# ===================================

function Main {
    try {
        Initialize-Script "Infrastructure Cleanup (PowerShell)"
        
        # Show warning for production environment
        if ($Environment -eq "prod") {
            Write-LogError "🚨 WARNING: PRODUCTION ENVIRONMENT DETECTED 🚨"
            Write-LogWarning "You are about to delete PRODUCTION resources!"
            
            if (-not $Force) {
                if (-not (Confirm-Action "Are you sure you want to delete PRODUCTION resources?" $false)) {
                    Write-LogInfo "Production cleanup cancelled - good choice!"
                    exit 0
                }
            }
        }
        
        # Main cleanup flow
        Initialize-Cleanup
        Test-CleanupPrerequisites
        Find-ResourcesToDelete
        Confirm-Cleanup
        Backup-ResourceConfiguration
        Remove-Resources
        Test-CleanupCompletion
        
        Write-LogSuccess "🎉 Cleanup completed!"
        
        # Final summary
        Write-LogSeparator
        Write-LogInfo "📋 Cleanup Summary:"
        Write-LogInfo "  • Environment: $Environment"
        Write-LogInfo "  • Resource Group: $ResourceGroup"
        Write-LogInfo "  • Project: $ProjectName"
        Write-LogInfo "  • Backup Created: Yes (check backup_* directories)"
        
        Write-Host ""
        Write-LogInfo "Next steps:"
        Write-LogInfo "  • Review the backup files if you need to restore anything"
        Write-LogInfo "  • Update any external references to the deleted resources"
        Write-LogInfo "  • Consider removing the resource group if it's now empty"
        
        Complete-Script $true
    }
    catch {
        Write-ErrorDetails $_.Exception.Message
        Complete-Script $false
        exit 1
    }
    finally {
        Remove-TempFiles
    }
}

# Show usage if help is requested
if ($args -contains "--help" -or $args -contains "-h") {
    Write-Host "Azure Infrastructure Cleanup Script (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\cleanup.ps1 [environment] [force]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  environment    Target environment (dev|prod). Default: dev"
    Write-Host "  force          Skip confirmation prompts (use with extreme caution)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\cleanup.ps1 dev         # Clean up development environment (with confirmations)"
    Write-Host "  .\cleanup.ps1 prod        # Clean up production environment (with confirmations)"
    Write-Host "  .\cleanup.ps1 dev -Force  # Clean up development environment (no confirmations)"
    Write-Host ""
    Write-Host "⚠️  WARNING: This script permanently deletes Azure resources!"
    Write-Host "⚠️  ALL DATA WILL BE LOST! Use with extreme caution!"
    Write-Host ""
    Write-Host "Safety features:"
    Write-Host "  • Multiple confirmation prompts"
    Write-Host "  • Resource configuration backup before deletion"
    Write-Host "  • Special handling for Key Vaults and databases"
    Write-Host "  • Resource filtering by project tags or naming convention"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  • Azure CLI installed and configured"
    Write-Host "  • Logged into Azure (az login)"
    Write-Host "  • Appropriate permissions to delete resources"
    exit 0
}

# Run main function
Main