# ===================================
# DEVELOPMENT ENVIRONMENT VALIDATION
# ===================================
# Simple validation script for dev environment
# Usage: .\environment.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ParametersDir = Join-Path $ProjectRoot "parameters"
$UtilsDir = Join-Path $ScriptDir "utils"

# Import common utilities
. (Join-Path $UtilsDir "common.ps1")

function Validate-DevEnvironment {
    Write-LogStep "Validating development environment configuration"
    
    $paramFile = Join-Path $ParametersDir "main.dev.bicepparam"
    
    if (-not (Test-Path $paramFile)) {
        Write-LogError "Parameter file for dev environment not found: $paramFile"
        return $false
    }
    
    $content = Get-Content $paramFile -Raw
    
    # Validation checks
    $validations = @()
    
    # Check SQL password
    if ($content -match "param sqlAdminPassword = '(.+)'") {
        $password = $Matches[1]
        if ([string]::IsNullOrEmpty($password)) {
            $validations += "⚠️  SQL password is empty - will prompt during deployment"
        } else {
            if ($password.Length -lt 8) {
                $validations += "❌ SQL password is too short (minimum 8 characters)"
            } else {
                $validations += "✅ SQL password configured"
            }
        }
    }
    
    # Check resource group name
    if ($content -match "param existingResourceGroupName = '(.+)'") {
        $rgName = $Matches[1]
        if ($rgName -match "^rgdev-") {
            $validations += "✅ Resource group follows dev naming convention"
        } else {
            $validations += "⚠️  Resource group doesn't follow dev naming convention (rgdev-*)"
        }
    }
    
    # Check environment setting
    if ($content -match "param environment = 'dev'") {
        $validations += "✅ Environment correctly set to dev"
    } else {
        $validations += "❌ Environment should be set to 'dev'"
    }
    
    Write-LogInfo "Validation Results:"
    foreach ($validation in $validations) {
        Write-LogInfo "  $validation"
    }
    
    $errors = $validations | Where-Object { $_ -match "❌" }
    if ($errors.Count -eq 0) {
        Write-LogSuccess "Dev environment configuration is valid"
        return $true
    } else {
        Write-LogWarning "Dev environment has $($errors.Count) configuration issues"
        return $false
    }
}

# Show configuration info
function Show-DevInfo {
    Write-LogInfo "=== DEVELOPMENT ENVIRONMENT INFO ==="
    Write-LogInfo ""
    Write-LogInfo "Parameter file: parameters/main.dev.bicepparam"
    Write-LogInfo "Resource group: rgdev-workshop-bicep"
    Write-LogInfo "Storage: Standard_LRS (local redundancy)"
    Write-LogInfo "SQL: Basic edition"
    Write-LogInfo "App Service: B1 (development tier)"
    Write-LogInfo ""
}

# Main execution
Show-DevInfo
Validate-DevEnvironment