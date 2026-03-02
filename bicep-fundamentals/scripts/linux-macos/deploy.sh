#!/bin/bash

# ===================================
# AZURE INFRASTRUCTURE DEPLOYMENT SCRIPT
# ===================================
# Deploys the personal expenses application infrastructure
# Following Azure best practices and project conventions
#
# Usage: ./deploy.sh [skip-validation]
#   skip-validation: skip pre-deployment validation (optional)
#
# Examples:
#   ./deploy.sh
#   ./deploy.sh skip-validation

set -euo pipefail

# ===================================
# SCRIPT CONFIGURATION
# ===================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
readonly UTILS_DIR="$SCRIPT_DIR/utils"

# Source common utilities
# shellcheck source=./utils/common.sh
source "$UTILS_DIR/common.sh"

# ===================================
# DEPLOYMENT CONFIGURATION
# ===================================

readonly MAIN_BICEP_FILE="$PROJECT_ROOT/main.bicep"
readonly PARAMETERS_DIR="$PROJECT_ROOT/parameters"
readonly DEFAULT_ENVIRONMENT="dev"
readonly DEPLOYMENT_TIMEOUT=1800  # 30 minutes

# ===================================
# SCRIPT VARIABLES
# ===================================

SKIP_VALIDATION="${1:-false}"
ENVIRONMENT="dev"
PARAMETER_FILE=""
RESOURCE_GROUP=""
PROJECT_NAME=""
DEPLOYMENT_NAME=""

# ===================================
# MAIN FUNCTIONS
# ===================================

setup_deployment() {
    log_step "Setting up deployment configuration"
    
    # Force environment to dev
    log_info "Using development environment (dev)"
    
    # Set parameter file path
    PARAMETER_FILE="$PARAMETERS_DIR/main.dev.bicepparam"
    
    # Validate required files exist
    check_file_exists "$MAIN_BICEP_FILE" "Main Bicep template" || exit 1
    check_file_exists "$PARAMETER_FILE" "Parameter file for dev" || exit 1
    
    # Extract configuration from parameter file
    RESOURCE_GROUP=$(get_resource_group_from_params "$PARAMETER_FILE")
    PROJECT_NAME=$(get_project_name_from_params "$PARAMETER_FILE")
    
    if [[ -z "$RESOURCE_GROUP" ]]; then
        log_error "Could not extract resource group name from parameter file"
        exit 1
    fi
    
    if [[ -z "$PROJECT_NAME" ]]; then
        log_error "Could not extract project name from parameter file"
        exit 1
    fi
    
    # Generate unique deployment name
    DEPLOYMENT_NAME=$(generate_deployment_name "${PROJECT_NAME}-dev")
    
    log_success "Deployment configuration set up"
    log_info "Environment: dev"
    log_info "Resource Group: $RESOURCE_GROUP"
    log_info "Project Name: $PROJECT_NAME"
    log_info "Parameter File: $PARAMETER_FILE"
    log_info "Deployment Name: $DEPLOYMENT_NAME"
}

validate_prerequisites() {
    log_step "Validating prerequisites"
    
    # Check Azure CLI and login status
    check_azure_cli
    check_azure_login
    
    # Check if resource group exists
    if ! check_resource_group_exists "$RESOURCE_GROUP"; then
        if confirm_action "Resource group '$RESOURCE_GROUP' does not exist. Create it now?"; then
            create_resource_group
        else
            log_error "Cannot proceed without resource group"
            exit 1
        fi
    fi
    
    # Validate Bicep syntax
    if ! validate_bicep_syntax "$MAIN_BICEP_FILE"; then
        log_error "Bicep template has syntax errors. Please fix them before deploying."
        exit 1
    fi
    
    log_success "Prerequisites validation completed"
}

create_resource_group() {
    local location
    location=$(extract_param_from_file "$PARAMETER_FILE" "location")
    
    if [[ -z "$location" ]]; then
        location=$(get_user_input "Enter Azure region for resource group" "East US 2")
    fi
    
    log_info "Creating resource group: $RESOURCE_GROUP in $location"
    
    if az group create \
        --name "$RESOURCE_GROUP" \
        --location "$location" \
        --tags project="$PROJECT_NAME" environment="dev" managedBy="bicep" \
        --output none; then
        log_success "Resource group created successfully"
    else
        log_error "Failed to create resource group"
        exit 1
    fi
}

run_what_if_validation() {
    if [[ "$SKIP_VALIDATION" == "skip-validation" ]]; then
        log_warning "Skipping what-if validation as requested"
        return 0
    fi
    
    log_step "Running what-if validation (this may take a few minutes)"
    
    if az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME-whatif" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETER_FILE" \
        --result-format FullResourcePayloads; then
        
        log_success "What-if validation completed"
        
        if ! confirm_action "Do you want to proceed with the deployment?" "true"; then
            log_info "Deployment cancelled by user"
            exit 0
        fi
    else
        log_error "What-if validation failed"
        log_info "Please review and fix any issues before proceeding"
        exit 1
    fi
}

handle_sql_password_prompt() {
    log_step "Checking SQL Server configuration"
    
    # Check if password is empty in parameter file
    local sql_password_line
    sql_password_line=$(grep "sqlAdminPassword" "$PARAMETER_FILE" || echo "")
    
    if [[ "$sql_password_line" =~ "= ''" ]] || [[ "$sql_password_line" =~ "= \"\"" ]]; then
        log_warning "SQL Admin password is empty in parameter file"
        
        if confirm_action "Do you want to set the password now?" "true"; then
            local password
            password=$(get_user_input "Enter SQL Admin password (min 8 chars, complexity required)" "" "true")
            
            if [[ ${#password} -lt 8 ]]; then
                log_error "Password must be at least 8 characters long"
                exit 1
            fi
            
            # Create temporary parameter file with password
            local temp_param_file="${PARAMETER_FILE}.tmp"
            sed "s/param sqlAdminPassword = ''/param sqlAdminPassword = '$password'/" "$PARAMETER_FILE" > "$temp_param_file"
            PARAMETER_FILE="$temp_param_file"
            
            log_success "Password configured for deployment"
        else
            log_error "Cannot proceed without SQL password"
            exit 1
        fi
    else
        log_success "SQL Admin password is configured"
    fi
}

deploy_infrastructure() {
    log_step "Starting infrastructure deployment"
    
    log_info "Deployment details:"
    log_info "  Template: $MAIN_BICEP_FILE"
    log_info "  Parameters: $PARAMETER_FILE"
    log_info "  Resource Group: $RESOURCE_GROUP"
    log_info "  Deployment Name: $DEPLOYMENT_NAME"
    log_info "  Environment: $ENVIRONMENT"
    
    # Start deployment
    if az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETER_FILE" \
        --verbose \
        --output json > deployment_output.json; then
        
        log_success "Deployment initiated successfully"
        
        # Wait for deployment to complete
        if wait_for_deployment "$DEPLOYMENT_NAME" "$RESOURCE_GROUP" "$DEPLOYMENT_TIMEOUT"; then
            show_deployment_results
        else
            show_deployment_errors
            exit 1
        fi
    else
        log_error "Failed to start deployment"
        exit 1
    fi
}

show_deployment_results() {
    log_step "Deployment Results"
    
    # Get deployment outputs
    log_info "Retrieving deployment outputs..."
    
    if az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.outputs" \
        --output table > deployment_outputs.txt 2>/dev/null; then
        
        log_success "Deployment completed successfully!"
        echo
        log_info "📋 Deployment Outputs:"
        cat deployment_outputs.txt
        
        # Extract key URLs and info
        local web_app_url
        web_app_url=$(az deployment group show \
            --name "$DEPLOYMENT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --query "properties.outputs.webAppUrl.value" \
            --output tsv 2>/dev/null || echo "")
        
        if [[ -n "$web_app_url" ]]; then
            echo
            log_success "🌐 Your application will be available at: $web_app_url"
        fi
        
        echo
        log_info "💾 Deployment details saved to:"
        log_info "  • deployment_output.json - Full deployment results"
        log_info "  • deployment_outputs.txt - Deployment outputs"
    else
        log_warning "Could not retrieve deployment outputs, but deployment succeeded"
    fi
}

show_deployment_errors() {
    log_step "Deployment Error Details"
    
    log_error "Deployment failed. Getting error details..."
    
    # Get deployment error details
    az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.error" \
        --output json > deployment_error.json 2>/dev/null || true
    
    if [[ -f deployment_error.json ]]; then
        log_info "Error details saved to: deployment_error.json"
        
        # Show error summary
        local error_message
        error_message=$(jq -r '.message // "Unknown error"' deployment_error.json 2>/dev/null || echo "Could not parse error")
        log_error "Error: $error_message"
    fi
    
    log_info "For detailed error analysis, run:"
    log_info "  az deployment group show --name '$DEPLOYMENT_NAME' --resource-group '$RESOURCE_GROUP'"
}

cleanup_temp_files() {
    # Clean up temporary files
    if [[ -f "${PARAMETER_FILE}.tmp" ]]; then
        rm -f "${PARAMETER_FILE}.tmp"
    fi
}

main() {
    init_script "Infrastructure Deployment"
    
    # Set up cleanup on exit
    trap cleanup_temp_files EXIT
    
    # Main deployment flow
    setup_deployment
    validate_prerequisites
    handle_sql_password_prompt
    run_what_if_validation
    deploy_infrastructure
    
    log_success "🎉 Infrastructure deployment completed successfully!"
    log_info "Next steps:"
    log_info "  1. Verify your application is accessible"
    log_info "  2. Configure your application code to use the deployed resources"
    log_info "  3. Set up CI/CD pipelines for automated deployments"
}

# ===================================
# SCRIPT EXECUTION
# ===================================

# Show usage if help is requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Azure Infrastructure Deployment Script"
    echo
    echo "Usage: $0 [environment] [skip-validation]"
    echo
    echo "Parameters:"
    echo "  environment      Target environment (dev|prod). Default: dev"
    echo "  skip-validation  Skip what-if validation (optional)"
    echo
    echo "Examples:"
    echo "  $0 dev                 # Deploy to development environment"
    echo "  $0 prod                # Deploy to production environment"  
    echo "  $0 dev skip-validation # Deploy without what-if validation"
    echo
    echo "Prerequisites:"
    echo "  • Azure CLI installed and configured"
    echo "  • Logged into Azure (az login)"
    echo "  • Appropriate permissions on target subscription"
    echo "  • Resource group specified in parameters file"
    exit 0
fi

# Run main function
main "$@"