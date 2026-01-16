#!/bin/bash
# ===================================
# DEVELOPMENT ENVIRONMENT VALIDATION
# ===================================
# Simple validation script for dev environment
# Usage: ./environment.sh

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PARAMETERS_DIR="$PROJECT_ROOT/parameters"
UTILS_DIR="$SCRIPT_DIR/utils"

# Import common utilities
source "$UTILS_DIR/common.sh"

validate_dev_environment() {
    log_step "Validating development environment configuration"
    
    local param_file="$PARAMETERS_DIR/main.dev.bicepparam"
    
    if [[ ! -f "$param_file" ]]; then
        log_error "Parameter file for dev environment not found: $param_file"
        return 1
    fi
    
    local content
    content=$(cat "$param_file")
    
    # Validation results array
    local validations=()
    
    # Check SQL password
    if [[ $content =~ param\ sqlAdminPassword\ =\ \'([^\']*)\' ]]; then
        local password="${BASH_REMATCH[1]}"
        if [[ -z "$password" ]]; then
            validations+=("⚠️  SQL password is empty - will prompt during deployment")
        else
            if [[ ${#password} -lt 8 ]]; then
                validations+=("❌ SQL password is too short (minimum 8 characters)")
            else
                validations+=("✅ SQL password configured")
            fi
        fi
    fi
    
    # Check resource group name
    if [[ $content =~ param\ existingResourceGroupName\ =\ \'([^\']+)\' ]]; then
        local rg_name="${BASH_REMATCH[1]}"
        if [[ $rg_name =~ ^rgdev- ]]; then
            validations+=("✅ Resource group follows dev naming convention")
        else
            validations+=("⚠️  Resource group doesn't follow dev naming convention (rgdev-*)")
        fi
    fi
    
    # Check environment setting
    if [[ $content =~ param\ environment\ =\ \'dev\' ]]; then
        validations+=("✅ Environment correctly set to dev")
    else
        validations+=("❌ Environment should be set to 'dev'")
    fi
    
    log_info "Validation Results:"
    for validation in "${validations[@]}"; do
        log_info "  $validation"
    done
    
    # Count errors
    local error_count=0
    for validation in "${validations[@]}"; do
        if [[ $validation =~ ❌ ]]; then
            ((error_count++))
        fi
    done
    
    if [[ $error_count -eq 0 ]]; then
        log_success "Dev environment configuration is valid"
        return 0
    else
        log_warning "Dev environment has $error_count configuration issues"
        return 1
    fi
}

show_dev_info() {
    log_info "=== DEVELOPMENT ENVIRONMENT INFO ==="
    echo
    log_info "Parameter file: parameters/main.dev.bicepparam"
    log_info "Resource group: rgdev-workshop-bicep"
    log_info "Storage: Standard_LRS (local redundancy)"
    log_info "SQL: Basic edition"
    log_info "App Service: B1 (development tier)"
    echo
}

# Main execution
show_dev_info
validate_dev_environment