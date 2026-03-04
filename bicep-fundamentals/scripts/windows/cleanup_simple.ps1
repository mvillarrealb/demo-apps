# ==============================================================================
# Simple Infrastructure Cleanup Script for Windows
# ==============================================================================
# This script deletes the Azure resource group and all its resources.
# 
# USAGE:
#   .\cleanup_simple.ps1
#
# REQUIREMENTS:
#   - PowerShell 5.1 or higher
#   - Azure CLI installed and logged in
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$Help
)

# Configuration
$ResourceGroupName = "rgdev-workshop-bicep"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Text,
        [ValidateSet('Red', 'Green', 'Yellow', 'Blue', 'Cyan', 'Magenta', 'White')]
        [string]$Color = 'White'
    )
    
    $colorMap = @{
        'Red' = 'Red'
        'Green' = 'Green' 
        'Yellow' = 'Yellow'
        'Blue' = 'Blue'
        'Cyan' = 'Cyan'
        'Magenta' = 'Magenta'
        'White' = 'White'
    }
    
    Write-Host $Text -ForegroundColor $colorMap[$Color]
}

# Show help if requested
if ($Help) {
    Write-Host @"
Simple Infrastructure Cleanup Script

USAGE:
    .\cleanup_simple.ps1

This script will delete the resource group 'rgdev-workshop-bicep' and all its resources.

REQUIREMENTS:
    - PowerShell 5.1 or higher
    - Azure CLI installed and logged in
"@
    exit 0
}

Write-ColorOutput -Text "===============================================" -Color "Blue"
Write-ColorOutput -Text "[INFO] Starting Infrastructure Cleanup" -Color "Blue"
Write-ColorOutput -Text "[INFO] Date: $(Get-Date)" -Color "Blue"
Write-ColorOutput -Text "===============================================" -Color "Blue"
Write-Host

# Check if Azure CLI is installed
try {
    $null = Get-Command az -ErrorAction Stop
} catch {
    Write-ColorOutput -Text "[ERROR] Azure CLI not found. Please install Azure CLI first." -Color "Red"
    exit 1
}

# Check if logged into Azure
try {
    $null = az account show 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in"
    }
} catch {
    Write-ColorOutput -Text "[ERROR] Not logged into Azure. Please run 'az login' first." -Color "Red"
    exit 1
}

# Show current subscription
Write-ColorOutput -Text "[INFO] Current Azure subscription:" -Color "Green"
az account show --query "{Name:name, SubscriptionId:id}" --output table
Write-Host

# Check if resource group exists
$groupExists = az group exists --name $ResourceGroupName 2>$null
if ($groupExists -eq "false" -or $LASTEXITCODE -ne 0) {
    Write-ColorOutput -Text "[INFO] Resource group '$ResourceGroupName' does not exist or has already been deleted." -Color "Yellow"
    Write-ColorOutput -Text "[SUCCESS] No resources to clean up!" -Color "Green"
    exit 0
}

# Show resources that will be deleted
Write-ColorOutput -Text "[INFO] Resources in '$ResourceGroupName' that will be deleted:" -Color "Yellow"
try {
    az resource list --resource-group $ResourceGroupName --output table
} catch {
    Write-ColorOutput -Text "Could not list resources" -Color "Yellow"
}
Write-Host

# Confirmation
Write-ColorOutput -Text "⚠️  WARNING: This will permanently delete ALL resources in the resource group!" -Color "Red"
Write-ColorOutput -Text "⚠️  This action CANNOT be undone!" -Color "Red"
Write-Host
$confirmation = Read-Host "Are you sure you want to delete the resource group '$ResourceGroupName'? (yes/no)"
Write-Host

if ($confirmation -in @('yes', 'YES', 'Yes', 'y', 'Y')) {
    Write-ColorOutput -Text "[INFO] Deleting resource group: $ResourceGroupName" -Color "Yellow"
    Write-ColorOutput -Text "[INFO] This may take several minutes..." -Color "Yellow"
    
    try {
        az group delete --name $ResourceGroupName --yes
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host
            Write-ColorOutput -Text "[SUCCESS] Resource group '$ResourceGroupName' has been deleted successfully!" -Color "Green"
            Write-ColorOutput -Text "[SUCCESS] All workshop resources have been cleaned up!" -Color "Green"
            Write-Host
            Write-ColorOutput -Text "[INFO] 🎉 Workshop cleanup completed!" -Color "Blue"
        } else {
            Write-Host
            Write-ColorOutput -Text "[ERROR] Failed to delete resource group. Please check the error messages above." -Color "Red"
            exit 1
        }
    } catch {
        Write-Host
        Write-ColorOutput -Text "[ERROR] Failed to delete resource group: $($_.Exception.Message)" -Color "Red"
        exit 1
    }
} else {
    Write-ColorOutput -Text "[INFO] Operation cancelled by user." -Color "Yellow"
    exit 0
}