# ===================================
# AZURE INFRASTRUCTURE DEPLOYMENT SCRIPT (PowerShell)
# ===================================
# Deploys the personal expenses application infrastructure
# Following Azure best practices and project conventions
#
# Usage: .\deploy.ps1 [environment] [skipValidation]
#   environment: dev|prod (default: dev)
#   skipValidation: skip pre-deployment validation (optional)
#
# Examples:
#   .\deploy.ps1 dev
#   .\deploy.ps1 prod
#   .\deploy.ps1 dev skipValidation

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Environment = "dev",
    
    [Parameter(Position = 1)]
    [switch]$SkipValidation
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
# DEPLOYMENT CONFIGURATION
# ===================================

$MainBicepFile = Join-Path $ProjectRoot "main.bicep"
$ParametersDir = Join-Path $ProjectRoot "parameters"
$DeploymentTimeout = 1800  # 30 minutes

# ===================================
# SCRIPT VARIABLES
# ===================================

$ParameterFile = ""
$ResourceGroup = ""
$ProjectName = ""
$DeploymentName = ""

# ===================================
# MAIN FUNCTIONS
# ===================================

function Initialize-Deployment {
    Write-LogStep "Setting up deployment configuration"
    
    # Force environment to dev
    if ($Environment -ne "dev") {
        Write-LogWarning "Only 'dev' environment is supported. Setting environment to 'dev'"
        $script:Environment = "dev"
    }
    
    # Set parameter file path
    $script:ParameterFile = Join-Path $ParametersDir "main.dev.bicepparam"
    
    # Validate required files exist
    if (-not (Test-FileExists $MainBicepFile "Main Bicep template")) {
        exit 1
    }
    
    if (-not (Test-FileExists $ParameterFile "Parameter file for dev")) {
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
    
    # Generate unique deployment name
    $script:DeploymentName = New-DeploymentName "$ProjectName-dev"
    
    Write-LogSuccess "Deployment configuration set up"
    Write-LogInfo "Environment: dev"
    Write-LogInfo "Resource Group: $ResourceGroup"
    Write-LogInfo "Project Name: $ProjectName"
    Write-LogInfo "Parameter File: $ParameterFile"
    Write-LogInfo "Deployment Name: $DeploymentName"
}

function Test-Prerequisites {
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
        if (Confirm-Action "Resource group '$ResourceGroup' does not exist. Create it now?") {
            New-ResourceGroup
        }
        else {
            Write-LogError "Cannot proceed without resource group"
            exit 1
        }
    }
    
    # Validate Bicep syntax
    if (-not (Test-BicepSyntax $MainBicepFile)) {
        Write-LogError "Bicep template has syntax errors. Please fix them before deploying."
        exit 1
    }
    
    Write-LogSuccess "Prerequisites validation completed"
}

function New-ResourceGroup {
    $location = Get-ParameterFromFile $ParameterFile "location"
    
    if ([string]::IsNullOrEmpty($location)) {
        $location = Get-UserInput "Enter Azure region for resource group" "East US 2"
    }
    
    Write-LogInfo "Creating resource group: $ResourceGroup in $location"
    
    $command = "az group create --name '$ResourceGroup' --location '$location' --tags project='$ProjectName' environment='dev' managedBy='bicep' --output none"
    
    if (Invoke-AzCommand $command "Resource group created successfully") {
        Write-LogSuccess "Resource group created successfully"
    }
    else {
        Write-LogError "Failed to create resource group"
        exit 1
    }
}

function Invoke-WhatIfValidation {
    if ($SkipValidation) {
        Write-LogWarning "Skipping what-if validation as requested"
        return
    }
    
    Write-LogStep "Running what-if validation (this may take a few minutes)"
    
    $command = "az deployment group what-if --resource-group '$ResourceGroup' --name '$DeploymentName-whatif' --template-file '$MainBicepFile' --parameters '$ParameterFile' --result-format FullResourcePayloads"
    
    if (Invoke-AzCommand $command "What-if validation completed") {
        Write-LogSuccess "What-if validation completed"
        
        if (-not (Confirm-Action "Do you want to proceed with the deployment?" $true)) {
            Write-LogInfo "Deployment cancelled by user"
            exit 0
        }
    }
    else {
        Write-LogError "What-if validation failed"
        Write-LogInfo "Please review and fix any issues before proceeding"
        exit 1
    }
}

function Resolve-SqlPassword {
    Write-LogStep "Checking SQL Server configuration"
    
    # Check if password is empty in parameter file
    $content = Get-Content $ParameterFile -Raw
    
    if ($content -match "sqlAdminPassword\s*=\s*''" -or $content -match 'sqlAdminPassword\s*=\s*""') {
        Write-LogWarning "SQL Admin password is empty in parameter file"
        
        if (Confirm-Action "Do you want to set the password now?" $true) {
            $password = Get-UserInput "Enter SQL Admin password (min 8 chars, complexity required)" "" $true
            
            if ($password.Length -lt 8) {
                Write-LogError "Password must be at least 8 characters long"
                exit 1
            }
            
            # Create temporary parameter file with password
            $tempParameterFile = "$ParameterFile.tmp"
            $content = $content -replace "param sqlAdminPassword = ''", "param sqlAdminPassword = '$password'"
            $content | Set-Content $tempParameterFile -Encoding UTF8
            $script:ParameterFile = $tempParameterFile
            
            Write-LogSuccess "Password configured for deployment"
        }
        else {
            Write-LogError "Cannot proceed without SQL password"
            exit 1
        }
    }
    else {
        Write-LogSuccess "SQL Admin password is configured"
    }
}

function Start-InfrastructureDeployment {
    Write-LogStep "Starting infrastructure deployment"
    
    Write-LogInfo "Deployment details:"
    Write-LogInfo "  Template: $MainBicepFile"
    Write-LogInfo "  Parameters: $ParameterFile"
    Write-LogInfo "  Resource Group: $ResourceGroup"
    Write-LogInfo "  Deployment Name: $DeploymentName"
    Write-LogInfo "  Environment: $Environment"
    
    # Start deployment
    $command = "az deployment group create --resource-group '$ResourceGroup' --name '$DeploymentName' --template-file '$MainBicepFile' --parameters '$ParameterFile' --verbose --output json"
    
    try {
        $deploymentOutput = Invoke-Expression $command
        if ($LASTEXITCODE -eq 0) {
            $deploymentOutput | Out-File "deployment_output.json" -Encoding UTF8
            Write-LogSuccess "Deployment initiated successfully"
            
            # Wait for deployment to complete
            if (Wait-ForDeployment $DeploymentName $ResourceGroup $DeploymentTimeout) {
                Show-DeploymentResults
            }
            else {
                Show-DeploymentErrors
                exit 1
            }
        }
        else {
            Write-LogError "Failed to start deployment"
            exit 1
        }
    }
    catch {
        Write-LogError "Failed to start deployment: $($_.Exception.Message)"
        exit 1
    }
}

function Show-DeploymentResults {
    Write-LogStep "Deployment Results"
    
    # Get deployment outputs
    Write-LogInfo "Retrieving deployment outputs..."
    
    try {
        $outputs = az deployment group show --name $DeploymentName --resource-group $ResourceGroup --query "properties.outputs" --output table 2>$null
        
        if ($outputs) {
            Write-LogSuccess "Deployment completed successfully!"
            Write-Host ""
            Write-LogInfo "📋 Deployment Outputs:"
            $outputs | Out-File "deployment_outputs.txt" -Encoding UTF8
            Write-Host $outputs
            
            # Extract key URLs and info
            $webAppUrl = az deployment group show --name $DeploymentName --resource-group $ResourceGroup --query "properties.outputs.webAppUrl.value" --output tsv 2>$null
            
            if (![string]::IsNullOrEmpty($webAppUrl)) {
                Write-Host ""
                Write-LogSuccess "🌐 Your application will be available at: $webAppUrl"
            }
            
            Write-Host ""
            Write-LogInfo "💾 Deployment details saved to:"
            Write-LogInfo "  • deployment_output.json - Full deployment results"
            Write-LogInfo "  • deployment_outputs.txt - Deployment outputs"
        }
        else {
            Write-LogWarning "Could not retrieve deployment outputs, but deployment succeeded"
        }
    }
    catch {
        Write-LogWarning "Could not retrieve deployment outputs, but deployment succeeded"
    }
}

function Show-DeploymentErrors {
    Write-LogStep "Deployment Error Details"
    
    Write-LogError "Deployment failed. Getting error details..."
    
    try {
        $errorDetails = az deployment group show --name $DeploymentName --resource-group $ResourceGroup --query "properties.error" --output json 2>$null
        
        if ($errorDetails) {
            $errorDetails | Out-File "deployment_error.json" -Encoding UTF8
            Write-LogInfo "Error details saved to: deployment_error.json"
            
            # Show error summary
            $errorObj = $errorDetails | ConvertFrom-Json
            $errorMessage = $errorObj.message
            if (![string]::IsNullOrEmpty($errorMessage)) {
                Write-LogError "Error: $errorMessage"
            }
        }
    }
    catch {
        Write-LogError "Could not retrieve error details"
    }
    
    Write-LogInfo "For detailed error analysis, run:"
    Write-LogInfo "  az deployment group show --name '$DeploymentName' --resource-group '$ResourceGroup'"
}

function Remove-TempFiles {
    # Clean up temporary files
    if (Test-Path "$ParameterFile.tmp") {
        Remove-Item "$ParameterFile.tmp" -Force
    }
}

# ===================================
# MAIN SCRIPT EXECUTION
# ===================================

function Main {
    try {
        Initialize-Script "Infrastructure Deployment (PowerShell)"
        
        # Main deployment flow
        Initialize-Deployment
        Test-Prerequisites
        Resolve-SqlPassword
        Invoke-WhatIfValidation
        Start-InfrastructureDeployment
        
        Write-LogSuccess "🎉 Infrastructure deployment completed successfully!"
        Write-LogInfo "Next steps:"
        Write-LogInfo "  1. Verify your application is accessible"
        Write-LogInfo "  2. Configure your application code to use the deployed resources"
        Write-LogInfo "  3. Set up CI/CD pipelines for automated deployments"
        
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
    Write-Host "Azure Infrastructure Deployment Script (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [environment] [skipValidation]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  environment      Target environment (dev|prod). Default: dev"
    Write-Host "  skipValidation   Skip what-if validation (optional)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 dev                 # Deploy to development environment"
    Write-Host "  .\deploy.ps1 prod                # Deploy to production environment"  
    Write-Host "  .\deploy.ps1 dev -skipValidation # Deploy without what-if validation"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  • Azure CLI installed and configured"
    Write-Host "  • Logged into Azure (az login)"
    Write-Host "  • Appropriate permissions on target subscription"
    Write-Host "  • Resource group specified in parameters file"
    exit 0
}

# Run main function
Main