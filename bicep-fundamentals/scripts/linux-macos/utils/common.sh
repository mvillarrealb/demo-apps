#!/bin/bash

# ===================================
# COMMON UTILITIES AND FUNCTIONS
# ===================================
# Shared functions for deployment scripts
# Following Azure best practices and project conventions

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ===================================
# LOGGING FUNCTIONS
# ===================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}[STEP]${NC} $1"
}

log_separator() {
    echo -e "${CYAN}===============================================${NC}"
}

# ===================================
# VALIDATION FUNCTIONS
# ===================================

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first:"
        log_info "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    log_success "Azure CLI found"
}

check_azure_login() {
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login' first"
        exit 1
    fi
    
    local account_name=$(az account show --query name --output tsv 2>/dev/null)
    local subscription_id=$(az account show --query id --output tsv 2>/dev/null)
    log_success "Logged into Azure"
    log_info "Account: ${account_name}"
    log_info "Subscription: ${subscription_id}"
}

check_resource_group_exists() {
    local rg_name="$1"
    
    if ! az group show --name "$rg_name" &> /dev/null; then
        log_error "Resource Group '$rg_name' does not exist"
        log_info "Please create it first or update the parameter file"
        return 1
    fi
    
    log_success "Resource Group '$rg_name' exists"
    return 0
}

validate_environment() {
    local env="$1"
    
    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        log_error "Invalid environment: '$env'. Must be 'dev' or 'prod'"
        return 1
    fi
    
    return 0
}

# ===================================
# FILE VALIDATION FUNCTIONS
# ===================================

check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "$description not found: $file_path"
        return 1
    fi
    
    log_success "$description found: $file_path"
    return 0
}

validate_bicep_syntax() {
    local bicep_file="$1"
    
    log_info "Validating Bicep syntax: $bicep_file"
    
    if az bicep build --file "$bicep_file" --stdout > /dev/null 2>&1; then
        log_success "Bicep syntax is valid"
        return 0
    else
        log_error "Bicep syntax validation failed"
        return 1
    fi
}

# ===================================
# USER INTERACTION FUNCTIONS
# ===================================

confirm_action() {
    local message="$1"
    local default_yes="${2:-false}"
    
    if [[ "$default_yes" == "true" ]]; then
        local prompt="$message [Y/n]: "
    else
        local prompt="$message [y/N]: "
    fi
    
    echo -n -e "${YELLOW}$prompt${NC}"
    read -r response
    
    if [[ "$default_yes" == "true" ]]; then
        [[ ! "$response" =~ ^[Nn]$ ]]
    else
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

get_user_input() {
    local prompt="$1"
    local default_value="$2"
    local is_secret="${3:-false}"
    
    if [[ -n "$default_value" ]]; then
        echo -n -e "${CYAN}$prompt [$default_value]: ${NC}"
    else
        echo -n -e "${CYAN}$prompt: ${NC}"
    fi
    
    if [[ "$is_secret" == "true" ]]; then
        read -rs user_input
        echo # New line after hidden input
    else
        read -r user_input
    fi
    
    if [[ -z "$user_input" && -n "$default_value" ]]; then
        user_input="$default_value"
    fi
    
    echo "$user_input"
}

# ===================================
# PARAMETER HANDLING FUNCTIONS
# ===================================

extract_param_from_file() {
    local param_file="$1"
    local param_name="$2"
    
    grep "^param $param_name" "$param_file" | cut -d"'" -f2 2>/dev/null || echo ""
}

get_resource_group_from_params() {
    local param_file="$1"
    extract_param_from_file "$param_file" "existingResourceGroupName"
}

get_project_name_from_params() {
    local param_file="$1"
    extract_param_from_file "$param_file" "projectName"
}

get_environment_from_params() {
    local param_file="$1"
    extract_param_from_file "$param_file" "environment"
}

# ===================================
# DEPLOYMENT UTILITY FUNCTIONS
# ===================================

generate_deployment_name() {
    local prefix="$1"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    echo "${prefix}-${timestamp}"
}

wait_for_deployment() {
    local deployment_name="$1"
    local resource_group="$2"
    local max_wait="${3:-1800}" # 30 minutes default
    
    log_info "Waiting for deployment to complete (max ${max_wait}s)..."
    
    local start_time=$(date +%s)
    while true; do
        local status=$(az deployment group show \
            --name "$deployment_name" \
            --resource-group "$resource_group" \
            --query "properties.provisioningState" \
            --output tsv 2>/dev/null)
        
        case "$status" in
            "Succeeded")
                log_success "Deployment completed successfully"
                return 0
                ;;
            "Failed"|"Cancelled")
                log_error "Deployment failed with status: $status"
                return 1
                ;;
            "Running"|"Accepted")
                local current_time=$(date +%s)
                local elapsed=$((current_time - start_time))
                
                if [[ $elapsed -gt $max_wait ]]; then
                    log_error "Deployment timeout after ${max_wait} seconds"
                    return 1
                fi
                
                echo -n "."
                sleep 10
                ;;
            *)
                log_warning "Unknown deployment status: $status"
                sleep 5
                ;;
        esac
    done
}

# ===================================
# CLEANUP UTILITY FUNCTIONS
# ===================================

list_project_resources() {
    local resource_group="$1"
    local project_name="$2"
    local environment="$3"
    
    log_info "Resources that will be affected in Resource Group: $resource_group"
    
    # Use tags or naming convention to filter resources
    az resource list \
        --resource-group "$resource_group" \
        --query "[?tags.project=='$project_name' && tags.environment=='$environment'].{Name:name, Type:type, Location:location}" \
        --output table 2>/dev/null || {
        
        # Fallback: list all resources in the resource group
        log_warning "Could not filter by tags, showing all resources in the resource group:"
        az resource list \
            --resource-group "$resource_group" \
            --query "[].{Name:name, Type:type, Location:location}" \
            --output table 2>/dev/null
    }
}

# ===================================
# ERROR HANDLING
# ===================================

handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed at line $line_number with exit code $exit_code"
        log_info "Check the error messages above for details"
        exit $exit_code
    fi
}

# Set up error trap
trap 'handle_error ${LINENO}' ERR

# ===================================
# SCRIPT INITIALIZATION
# ===================================

init_script() {
    local script_name="$1"
    
    log_separator
    log_info "Starting $script_name"
    log_info "Date: $(date)"
    log_info "User: $(whoami)"
    log_info "Directory: $(pwd)"
    log_separator
}

cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Script completed successfully"
    else
        log_error "Script completed with errors (exit code: $exit_code)"
    fi
    
    log_separator
}

# Set up exit trap
trap cleanup_on_exit EXIT