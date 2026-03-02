# ===================================
# AZURE INFRASTRUCTURE VALIDATION SCRIPT (PowerShell)
# ===================================
# Validates the infrastructure template without deploying resources
# Using Azure's what-if functionality and syntax checking
#
# Usage: .\validate.ps1 [environment]
#   environment: dev|prod (default: dev)
#
# Examples:
#   .\validate.ps1 dev
#   .\validate.ps1 prod

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
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
# VALIDATION CONFIGURATION
# ===================================

$MainBicepFile = Join-Path $ProjectRoot "main.bicep"
$ParametersDir = Join-Path $ProjectRoot "parameters"

# ===================================
# SCRIPT VARIABLES
# ===================================

$ParameterFile = ""
$ResourceGroup = ""
$ProjectName = ""

# ===================================
# MAIN FUNCTIONS
# ===================================

function Initialize-Validation {
    Write-LogStep "Setting up validation configuration"
    
    # Validate environment parameter
    if (-not (Test-Environment $Environment)) {
        Write-LogError "Please specify a valid environment: dev or prod"
        exit 1
    }
    
    # Set parameter file path
    $script:ParameterFile = Join-Path $ParametersDir "main.$Environment.bicepparam"
    
    # Validate required files exist
    if (-not (Test-FileExists $MainBicepFile "Main Bicep template")) {
        exit 1
    }
    
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
    
    Write-LogSuccess "Validation configuration set up"
    Write-LogInfo "Environment: $Environment"
    Write-LogInfo "Resource Group: $ResourceGroup"
    Write-LogInfo "Project Name: $ProjectName"
    Write-LogInfo "Parameter File: $ParameterFile"
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
    
    # Check if resource group exists (for what-if)
    if (-not (Test-ResourceGroupExists $ResourceGroup)) {
        Write-LogWarning "Resource group '$ResourceGroup' does not exist"
        Write-LogInfo "What-if analysis will show resource group creation as well"
    }
    
    Write-LogSuccess "Prerequisites validation completed"
}

function Test-BicepSyntaxValidation {
    Write-LogStep "Validating Bicep syntax and compilation"
    
    # Check main template syntax
    Write-LogInfo "Checking main template: $MainBicepFile"
    if (Test-BicepSyntax $MainBicepFile) {
        Write-LogSuccess "✅ Main template syntax is valid"
    }
    else {
        Write-LogError "❌ Main template has syntax errors"
        Write-LogInfo "Running detailed syntax check..."
        az bicep build --file $MainBicepFile --stdout
        return $false
    }
    
    # Check all module files
    Write-LogInfo "Checking module templates..."
    $modulesDir = Join-Path $ProjectRoot "modules"
    $modulesValid = $true
    
    if (Test-Path $modulesDir) {
        $moduleFiles = Get-ChildItem $modulesDir -Filter "*.bicep" -Recurse
        
        foreach ($moduleFile in $moduleFiles) {
            $moduleName = $moduleFile.BaseName
            
            Write-LogInfo "Checking module: $moduleName"
            if (Test-BicepSyntax $moduleFile.FullName) {
                Write-LogSuccess "  ✅ Module $moduleName is valid"
            }
            else {
                Write-LogError "  ❌ Module $moduleName has syntax errors"
                $modulesValid = $false
            }
        }
    }
    
    if ($modulesValid) {
        Write-LogSuccess "All Bicep templates are syntactically valid"
        return $true
    }
    else {
        Write-LogError "Some Bicep templates have syntax errors"
        return $false
    }
}

function Test-ParameterFileValidation {
    Write-LogStep "Validating parameter file"
    
    Write-LogInfo "Checking parameter file: $ParameterFile"
    
    # Check if parameter file references correct template
    $firstLine = Get-Content $ParameterFile -TotalCount 1
    
    if ($firstLine -match "using '../main.bicep'") {
        Write-LogSuccess "✅ Parameter file references correct template"
    }
    else {
        Write-LogWarning "Parameter file may not reference the correct template"
        Write-LogInfo "Expected: using '../main.bicep'"
        Write-LogInfo "Found: $firstLine"
    }
    
    # Check for required parameters
    Write-LogInfo "Checking required parameters..."
    
    $requiredParams = @(
        "projectName",
        "environment", 
        "location",
        "existingResourceGroupName",
        "sqlAdminLogin"
    )
    
    $missingParams = @()
    
    foreach ($param in $requiredParams) {
        $value = Get-ParameterFromFile $ParameterFile $param
        if (![string]::IsNullOrEmpty($value)) {
            Write-LogSuccess "  ✅ $param`: '$value'"
        }
        elseif ((Get-Content $ParameterFile -Raw) -match "param $param") {
            Write-LogWarning "  ⚠️  $param`: configured but empty"
        }
        else {
            $missingParams += $param
            Write-LogError "  ❌ $param`: missing"
        }
    }
    
    # Check for SQL password (special case)
    $content = Get-Content $ParameterFile -Raw
    if ($content -match "param sqlAdminPassword") {
        if ($content -match "sqlAdminPassword\s*=\s*''" -or $content -match 'sqlAdminPassword\s*=\s*""') {
            Write-LogWarning "  ⚠️  sqlAdminPassword: empty (will prompt during deployment)"
        }
        else {
            Write-LogSuccess "  ✅ sqlAdminPassword: configured"
        }
    }
    else {
        $missingParams += "sqlAdminPassword"
        Write-LogError "  ❌ sqlAdminPassword: missing"
    }
    
    if ($missingParams.Count -eq 0) {
        Write-LogSuccess "Parameter file validation completed"
        return $true
    }
    else {
        Write-LogError "Parameter file is missing required parameters: $($missingParams -join ', ')"
        return $false
    }
}

function Invoke-TemplateValidation {
    Write-LogStep "Running Azure template validation"
    
    Write-LogInfo "Validating template against Azure Resource Manager..."
    
    $validationName = New-DeploymentName "$ProjectName-$Environment-validate"
    
    try {
        $result = az deployment group validate --resource-group $ResourceGroup --name $validationName --template-file $MainBicepFile --parameters $ParameterFile --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $resultObj = $result | ConvertFrom-Json
            $resultObj | ConvertTo-Json -Depth 10 | Out-File "validation_result.json" -Encoding UTF8
            
            Write-LogSuccess "✅ Template validation passed"
            
            # Show validation summary
            $validatedResources = $resultObj.properties.validatedResources.Count
            Write-LogInfo "Resources to be created/updated: $validatedResources"
        }
        else {
            Write-LogError "❌ Template validation failed"
            $result | Out-File "validation_result.json" -Encoding UTF8
            Write-LogInfo "Validation errors saved to: validation_result.json"
            
            # Try to extract and display errors
            try {
                $errorObj = $result | ConvertFrom-Json
                $errorMessage = $errorObj.error.message
                if (![string]::IsNullOrEmpty($errorMessage)) {
                    Write-LogError "Validation error: $errorMessage"
                }
            }
            catch {
                Write-LogError "Could not parse validation error"
            }
            
            return $false
        }
    }
    catch {
        Write-LogError "❌ Template validation failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Invoke-WhatIfAnalysis {
    Write-LogStep "Running what-if analysis"
    
    Write-LogInfo "Analyzing what changes would be made..."
    Write-LogWarning "This may take several minutes for complex templates"
    
    $whatifName = New-DeploymentName "$ProjectName-$Environment-whatif"
    
    try {
        $result = az deployment group what-if --resource-group $ResourceGroup --name $whatifName --template-file $MainBicepFile --parameters $ParameterFile --result-format FullResourcePayloads --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $result | Out-File "whatif_result.json" -Encoding UTF8
            Write-LogSuccess "✅ What-if analysis completed"
            
            # Display what-if results in a more readable format
            Write-LogInfo "📋 What-if Analysis Results:"
            Write-Host ""
            
            # Show the what-if output in a clean format
            $simpleResult = az deployment group what-if --resource-group $ResourceGroup --name $whatifName --template-file $MainBicepFile --parameters $ParameterFile --result-format ResourceIdOnly 2>$null
            
            if ($simpleResult) {
                Write-Host $simpleResult
            }
            else {
                Write-LogInfo "Detailed what-if results saved to: whatif_result.json"
            }
        }
        else {
            Write-LogError "❌ What-if analysis failed"
            $result | Out-File "whatif_result.json" -Encoding UTF8
            Write-LogInfo "What-if errors saved to: whatif_result.json"
            
            try {
                $errorObj = $result | ConvertFrom-Json
                $errorMessage = $errorObj.error.message
                if (![string]::IsNullOrEmpty($errorMessage)) {
                    Write-LogError "What-if error: $errorMessage"
                }
            }
            catch {
                Write-LogError "Could not parse what-if error"
            }
            
            return $false
        }
    }
    catch {
        Write-LogError "❌ What-if analysis failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function New-ValidationReport {
    Write-LogStep "Generating validation report"
    
    $reportFile = "validation_report_$($Environment)_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    $validationPassed = Test-Path "validation_result.json"
    $whatifPassed = Test-Path "whatif_result.json"
    $rgExists = Test-ResourceGroupExists $ResourceGroup 2>$null
    
    $reportContent = @"
# Infrastructure Validation Report

**Date:** $(Get-Date)
**Environment:** $Environment
**Project:** $ProjectName
**Resource Group:** $ResourceGroup

## Validation Summary

### Template Files
- Main Template: ``$MainBicepFile``
- Parameter File: ``$ParameterFile``

### Validation Results
$(if ($validationPassed) { "✅ ARM Template Validation: PASSED" } else { "❌ ARM Template Validation: FAILED" })
$(if ($whatifPassed) { "✅ What-If Analysis: COMPLETED" } else { "❌ What-If Analysis: FAILED" })

### Resource Group Status
$(if ($rgExists) { "✅ Resource Group '$ResourceGroup' exists" } else { "⚠️ Resource Group '$ResourceGroup' will be created" })

### Generated Files
- Validation Results: ``validation_result.json``
- What-If Results: ``whatif_result.json``
- This Report: ``$reportFile``

## Next Steps

1. Review the what-if analysis results to understand what changes will be made
2. If validation passed, you can proceed with deployment using:
   ``````powershell
   .\deploy.ps1 $Environment
   ``````
3. If validation failed, review the error messages and fix any issues before retrying

## Additional Information

For detailed analysis of validation or what-if results, examine the JSON files generated during this validation.

"@

    $reportContent | Out-File $reportFile -Encoding UTF8
    Write-LogSuccess "Validation report generated: $reportFile"
}

# ===================================
# MAIN SCRIPT EXECUTION
# ===================================

function Main {
    try {
        Initialize-Script "Infrastructure Validation (PowerShell)"
        
        # Main validation flow
        Initialize-Validation
        Test-Prerequisites
        
        $validationPassed = $true
        
        # Run all validations
        if (-not (Test-BicepSyntaxValidation)) {
            $validationPassed = $false
        }
        
        if (-not (Test-ParameterFileValidation)) {
            $validationPassed = $false
        }
        
        # Only run Azure validations if resource group exists or can be checked
        if (Test-ResourceGroupExists $ResourceGroup 2>$null) {
            if (-not (Invoke-TemplateValidation)) {
                $validationPassed = $false
            }
            
            if (-not (Invoke-WhatIfAnalysis)) {
                $validationPassed = $false
            }
        }
        else {
            Write-LogWarning "Skipping Azure template validation and what-if analysis"
            Write-LogWarning "Resource group '$ResourceGroup' does not exist"
            Write-LogInfo "These validations will run during deployment when the resource group is available"
        }
        
        # Generate report regardless of validation results
        New-ValidationReport
        
        # Final validation summary
        Write-LogSeparator
        if ($validationPassed) {
            Write-LogSuccess "🎉 All validations passed!"
            Write-LogInfo "Your template is ready for deployment"
            Write-Host ""
            Write-LogInfo "To deploy this infrastructure, run:"
            Write-LogInfo "  .\deploy.ps1 $Environment"
        }
        else {
            Write-LogError "❌ Some validations failed"
            Write-LogInfo "Please review the errors above and fix any issues before deployment"
            exit 1
        }
        
        Complete-Script $validationPassed
    }
    catch {
        Write-ErrorDetails $_.Exception.Message
        Complete-Script $false
        exit 1
    }
}

# Show usage if help is requested
if ($args -contains "--help" -or $args -contains "-h") {
    Write-Host "Azure Infrastructure Validation Script (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\validate.ps1 [environment]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  environment    Target environment (dev|prod). Default: dev"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\validate.ps1 dev         # Validate development environment"
    Write-Host "  .\validate.ps1 prod        # Validate production environment"
    Write-Host ""
    Write-Host "What this script does:"
    Write-Host "  • Validates Bicep syntax for all templates"
    Write-Host "  • Checks parameter file completeness"
    Write-Host "  • Runs Azure Resource Manager template validation"
    Write-Host "  • Performs what-if analysis to preview changes"
    Write-Host "  • Generates a comprehensive validation report"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  • Azure CLI installed and configured"
    Write-Host "  • Logged into Azure (az login)"
    Write-Host "  • Read permissions on target subscription"
    exit 0
}

# Run main function
Main