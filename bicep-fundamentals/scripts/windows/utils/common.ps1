# ===================================
# COMMON UTILITIES AND FUNCTIONS (PowerShell)
# ===================================
# Shared functions for deployment scripts
# Following Azure best practices and project conventions

# ===================================
# LOGGING FUNCTIONS
# ===================================

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-LogStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "[STEP] $Message" -ForegroundColor Magenta
}

function Write-LogSeparator {
    Write-Host "===============================================" -ForegroundColor Cyan
}

# ===================================
# VALIDATION FUNCTIONS
# ===================================

function Test-AzureCLI {
    try {
        $null = Get-Command az -ErrorAction Stop
        Write-LogSuccess "Azure CLI found"
        return $true
    }
    catch {
        Write-LogError "Azure CLI is not installed. Please install it first:"
        Write-LogInfo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return $false
    }
}

function Test-AzureLogin {
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-LogSuccess "Logged into Azure"
            Write-LogInfo "Account: $($account.name)"
            Write-LogInfo "Subscription: $($account.id)"
            return $true
        }
        else {
            throw "Not logged in"
        }
    }
    catch {
        Write-LogError "Not logged into Azure. Please run 'az login' first"
        return $false
    }
}

function Test-ResourceGroupExists {
    param([string]$ResourceGroupName)
    
    try {
        $rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        if ($rg) {
            Write-LogSuccess "Resource Group '$ResourceGroupName' exists"
            return $true
        }
        else {
            Write-LogError "Resource Group '$ResourceGroupName' does not exist"
            Write-LogInfo "Please create it first or update the parameter file"
            return $false
        }
    }
    catch {
        Write-LogError "Resource Group '$ResourceGroupName' does not exist"
        Write-LogInfo "Please create it first or update the parameter file"
        return $false
    }
}

function Test-Environment {
    param([string]$Environment)
    
    if ($Environment -notin @("dev", "prod")) {
        Write-LogError "Invalid environment: '$Environment'. Must be 'dev' or 'prod'"
        return $false
    }
    
    return $true
}

# ===================================
# FILE VALIDATION FUNCTIONS
# ===================================

function Test-FileExists {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-LogError "$Description not found: $FilePath"
        return $false
    }
    
    Write-LogSuccess "$Description found: $FilePath"
    return $true
}

function Test-BicepSyntax {
    param([string]$BicepFile)
    
    Write-LogInfo "Validating Bicep syntax: $BicepFile"
    
    try {
        $result = az bicep build --file $BicepFile --stdout 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Bicep syntax is valid"
            return $true
        }
        else {
            Write-LogError "Bicep syntax validation failed"
            return $false
        }
    }
    catch {
        Write-LogError "Bicep syntax validation failed"
        return $false
    }
}

# ===================================
# USER INTERACTION FUNCTIONS
# ===================================

function Confirm-Action {
    param(
        [string]$Message,
        [bool]$DefaultYes = $false
    )
    
    if ($DefaultYes) {
        $prompt = "$Message [Y/n]: "
    }
    else {
        $prompt = "$Message [y/N]: "
    }
    
    Write-Host $prompt -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($DefaultYes) {
        return $response -notmatch "^[Nn]$"
    }
    else {
        return $response -match "^[Yy]$"
    }
}

function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$DefaultValue = "",
        [bool]$IsSecret = $false
    )
    
    if ($DefaultValue) {
        $fullPrompt = "$Prompt [$DefaultValue]: "
    }
    else {
        $fullPrompt = "$Prompt: "
    }
    
    Write-Host $fullPrompt -ForegroundColor Cyan -NoNewline
    
    if ($IsSecret) {
        $secureString = Read-Host -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $userInput = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    else {
        $userInput = Read-Host
    }
    
    if ([string]::IsNullOrEmpty($userInput) -and $DefaultValue) {
        $userInput = $DefaultValue
    }
    
    return $userInput
}

# ===================================
# PARAMETER HANDLING FUNCTIONS
# ===================================

function Get-ParameterFromFile {
    param(
        [string]$ParameterFile,
        [string]$ParameterName
    )
    
    try {
        $content = Get-Content $ParameterFile -Raw
        $pattern = "param\s+$ParameterName\s*=\s*'([^']*)'"
        if ($content -match $pattern) {
            return $Matches[1]
        }
        return ""
    }
    catch {
        return ""
    }
}

function Get-ResourceGroupFromParams {
    param([string]$ParameterFile)
    return Get-ParameterFromFile -ParameterFile $ParameterFile -ParameterName "existingResourceGroupName"
}

function Get-ProjectNameFromParams {
    param([string]$ParameterFile)
    return Get-ParameterFromFile -ParameterFile $ParameterFile -ParameterName "projectName"
}

function Get-EnvironmentFromParams {
    param([string]$ParameterFile)
    return Get-ParameterFromFile -ParameterFile $ParameterFile -ParameterName "environment"
}

# ===================================
# DEPLOYMENT UTILITY FUNCTIONS
# ===================================

function New-DeploymentName {
    param([string]$Prefix)
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    return "$Prefix-$timestamp"
}

function Wait-ForDeployment {
    param(
        [string]$DeploymentName,
        [string]$ResourceGroup,
        [int]$MaxWaitSeconds = 1800
    )
    
    Write-LogInfo "Waiting for deployment to complete (max $MaxWaitSeconds seconds)..."
    
    $startTime = Get-Date
    while ($true) {
        try {
            $deployment = az deployment group show --name $DeploymentName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
            $status = $deployment.properties.provisioningState
            
            switch ($status) {
                "Succeeded" {
                    Write-LogSuccess "Deployment completed successfully"
                    return $true
                }
                "Failed" {
                    Write-LogError "Deployment failed with status: $status"
                    return $false
                }
                "Cancelled" {
                    Write-LogError "Deployment was cancelled"
                    return $false
                }
                { $_ -in @("Running", "Accepted") } {
                    $elapsed = (Get-Date) - $startTime
                    if ($elapsed.TotalSeconds -gt $MaxWaitSeconds) {
                        Write-LogError "Deployment timeout after $MaxWaitSeconds seconds"
                        return $false
                    }
                    Write-Host "." -NoNewline
                    Start-Sleep -Seconds 10
                }
                default {
                    Write-LogWarning "Unknown deployment status: $status"
                    Start-Sleep -Seconds 5
                }
            }
        }
        catch {
            Write-LogWarning "Could not check deployment status"
            Start-Sleep -Seconds 5
        }
    }
}

# ===================================
# CLEANUP UTILITY FUNCTIONS
# ===================================

function Get-ProjectResources {
    param(
        [string]$ResourceGroup,
        [string]$ProjectName,
        [string]$Environment
    )
    
    Write-LogInfo "Resources that will be affected in Resource Group: $ResourceGroup"
    
    try {
        # Try to get resources by tags first
        $resources = az resource list --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
        $projectResources = $resources | Where-Object { 
            $_.tags.project -eq $ProjectName -and $_.tags.environment -eq $Environment 
        }
        
        if ($projectResources) {
            $projectResources | Format-Table Name, Type, Location -AutoSize
        }
        else {
            Write-LogWarning "Could not filter by tags, showing all resources in the resource group:"
            $resources | Format-Table Name, Type, Location -AutoSize
        }
    }
    catch {
        Write-LogError "Could not list resources in resource group"
    }
}

# ===================================
# ERROR HANDLING
# ===================================

function Write-ErrorDetails {
    param(
        [string]$ErrorMessage,
        [int]$LineNumber = 0
    )
    
    Write-LogError "Script failed at line $LineNumber"
    Write-LogError "Error: $ErrorMessage"
    Write-LogInfo "Check the error messages above for details"
}

# ===================================
# SCRIPT INITIALIZATION
# ===================================

function Initialize-Script {
    param([string]$ScriptName)
    
    Write-LogSeparator
    Write-LogInfo "Starting $ScriptName"
    Write-LogInfo "Date: $(Get-Date)"
    Write-LogInfo "User: $env:USERNAME"
    Write-LogInfo "Directory: $(Get-Location)"
    Write-LogSeparator
}

function Complete-Script {
    param([bool]$Success = $true)
    
    if ($Success) {
        Write-LogSuccess "Script completed successfully"
    }
    else {
        Write-LogError "Script completed with errors"
    }
    
    Write-LogSeparator
}

# ===================================
# AZURE CLI HELPERS
# ===================================

function Invoke-AzCommand {
    param(
        [string]$Command,
        [string]$SuccessMessage = "",
        [string]$ErrorMessage = "Command failed"
    )
    
    try {
        $result = Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            if ($SuccessMessage) {
                Write-LogSuccess $SuccessMessage
            }
            return $result
        }
        else {
            Write-LogError "$ErrorMessage (Exit code: $LASTEXITCODE)"
            return $null
        }
    }
    catch {
        Write-LogError "$ErrorMessage - $($_.Exception.Message)"
        return $null
    }
}

# ===================================
# EXPORT FUNCTIONS
# ===================================

Export-ModuleMember -Function *