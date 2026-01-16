#!/bin/bash

# ===================================
# AZURE INFRASTRUCTURE VALIDATION SCRIPT
# ===================================
# Validates the infrastructure template without deploying resources
# Using Azure's what-if functionality and syntax checking
#
# Usage: ./validate.sh [environment]
#   environment: dev|prod (default: dev)
#
# Examples:
#   ./validate.sh dev
#   ./validate.sh prod

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
# VALIDATION CONFIGURATION
# ===================================

readonly MAIN_BICEP_FILE="$PROJECT_ROOT/main.bicep"
readonly PARAMETERS_DIR="$PROJECT_ROOT/parameters"
readonly DEFAULT_ENVIRONMENT="dev"

# ===================================
# SCRIPT VARIABLES
# ===================================

ENVIRONMENT="${1:-$DEFAULT_ENVIRONMENT}"
PARAMETER_FILE=""
RESOURCE_GROUP=""
PROJECT_NAME=""

# ===================================
# MAIN FUNCTIONS
# ===================================

setup_validation() {
    log_step "Setting up validation configuration"
    
    # Validate environment parameter
    if ! validate_environment "$ENVIRONMENT"; then
        log_error "Please specify a valid environment: dev or prod"
        exit 1
    fi
    
    # Set parameter file path
    PARAMETER_FILE="$PARAMETERS_DIR/main.$ENVIRONMENT.bicepparam"
    
    # Validate required files exist
    check_file_exists "$MAIN_BICEP_FILE" "Main Bicep template" || exit 1
    check_file_exists "$PARAMETER_FILE" "Parameter file for $ENVIRONMENT" || exit 1
    
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
    
    log_success "Validation configuration set up"
    log_info "Environment: $ENVIRONMENT"
    log_info "Resource Group: $RESOURCE_GROUP"
    log_info "Project Name: $PROJECT_NAME"
    log_info "Parameter File: $PARAMETER_FILE"
}

validate_prerequisites() {
    log_step "Validating prerequisites"
    
    # Check Azure CLI and login status
    check_azure_cli
    check_azure_login
    
    # Check if resource group exists (for what-if)
    if ! check_resource_group_exists "$RESOURCE_GROUP"; then
        log_warning "Resource group '$RESOURCE_GROUP' does not exist"
        log_info "What-if analysis will show resource group creation as well"
    fi
    
    log_success "Prerequisites validation completed"
}

validate_bicep_syntax() {
    log_step "Validating Bicep syntax and compilation"
    
    # Check main template syntax
    log_info "Checking main template: $MAIN_BICEP_FILE"
    if az bicep build --file "$MAIN_BICEP_FILE" --stdout > /dev/null 2>&1; then
        log_success "✅ Main template syntax is valid"
    else
        log_error "❌ Main template has syntax errors"
        log_info "Running detailed syntax check..."
        az bicep build --file "$MAIN_BICEP_FILE" --stdout || true
        return 1
    fi
    
    # Check all module files
    log_info "Checking module templates..."
    local modules_dir="$PROJECT_ROOT/modules"
    local modules_valid=true
    
    if [[ -d "$modules_dir" ]]; then
        while IFS= read -r -d '' module_file; do
            local module_name
            module_name=$(basename "$module_file" .bicep)
            
            log_info "Checking module: $module_name"
            if az bicep build --file "$module_file" --stdout > /dev/null 2>&1; then
                log_success "  ✅ Module $module_name is valid"
            else
                log_error "  ❌ Module $module_name has syntax errors"
                modules_valid=false
            fi
        done < <(find "$modules_dir" -name "*.bicep" -print0)
    fi
    
    if [[ "$modules_valid" == "true" ]]; then
        log_success "All Bicep templates are syntactically valid"
        return 0
    else
        log_error "Some Bicep templates have syntax errors"
        return 1
    fi
}

validate_parameter_file() {
    log_step "Validating parameter file"
    
    log_info "Checking parameter file: $PARAMETER_FILE"
    
    # Check if parameter file references correct template
    local using_line
    using_line=$(head -1 "$PARAMETER_FILE")
    
    if [[ "$using_line" =~ "using '../main.bicep'" ]]; then
        log_success "✅ Parameter file references correct template"
    else
        log_warning "Parameter file may not reference the correct template"
        log_info "Expected: using '../main.bicep'"
        log_info "Found: $using_line"
    fi
    
    # Check for required parameters
    log_info "Checking required parameters..."
    
    local required_params=(
        "projectName"
        "environment" 
        "location"
        "existingResourceGroupName"
        "sqlAdminLogin"
    )
    
    local missing_params=()
    
    for param in "${required_params[@]}"; do
        if grep -q "param $param" "$PARAMETER_FILE"; then
            local value
            value=$(extract_param_from_file "$PARAMETER_FILE" "$param")
            if [[ -n "$value" ]]; then
                log_success "  ✅ $param: '$value'"
            else
                log_warning "  ⚠️  $param: configured but empty"
            fi
        else
            missing_params+=("$param")
            log_error "  ❌ $param: missing"
        fi
    done
    
    # Check for SQL password (special case)
    if grep -q "param sqlAdminPassword" "$PARAMETER_FILE"; then
        local sql_password_line
        sql_password_line=$(grep "sqlAdminPassword" "$PARAMETER_FILE")
        if [[ "$sql_password_line" =~ "= ''" ]] || [[ "$sql_password_line" =~ "= \"\"" ]]; then
            log_warning "  ⚠️  sqlAdminPassword: empty (will prompt during deployment)"
        else
            log_success "  ✅ sqlAdminPassword: configured"
        fi
    else
        missing_params+=("sqlAdminPassword")
        log_error "  ❌ sqlAdminPassword: missing"
    fi
    
    if [[ ${#missing_params[@]} -eq 0 ]]; then
        log_success "Parameter file validation completed"
        return 0
    else
        log_error "Parameter file is missing required parameters: ${missing_params[*]}"
        return 1
    fi
}

run_template_validation() {
    log_step "Running Azure template validation"
    
    log_info "Validating template against Azure Resource Manager..."
    
    local validation_name
    validation_name=$(generate_deployment_name "${PROJECT_NAME}-${ENVIRONMENT}-validate")
    
    if az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --name "$validation_name" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETER_FILE" \
        --output json > validation_result.json 2>&1; then
        
        log_success "✅ Template validation passed"
        
        # Show validation summary
        local validated_resources
        validated_resources=$(jq -r '.properties.validatedResources | length' validation_result.json 2>/dev/null || echo "unknown")
        log_info "Resources to be created/updated: $validated_resources"
        
    else
        log_error "❌ Template validation failed"
        log_info "Validation errors saved to: validation_result.json"
        
        # Try to extract and display errors
        if [[ -f validation_result.json ]]; then
            local error_message
            error_message=$(jq -r '.error.message // "Unknown validation error"' validation_result.json 2>/dev/null || echo "Could not parse validation error")
            log_error "Validation error: $error_message"
        fi
        
        return 1
    fi
}

run_what_if_analysis() {
    log_step "Running what-if analysis"
    
    log_info "Analyzing what changes would be made..."
    log_warning "This may take several minutes for complex templates"
    
    local whatif_name
    whatif_name=$(generate_deployment_name "${PROJECT_NAME}-${ENVIRONMENT}-whatif")
    
    if az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --name "$whatif_name" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETER_FILE" \
        --result-format FullResourcePayloads \
        --output json > whatif_result.json 2>&1; then
        
        log_success "✅ What-if analysis completed"
        
        # Display what-if results in a more readable format
        log_info "📋 What-if Analysis Results:"
        echo
        
        # Show the what-if output in a clean format
        az deployment group what-if \
            --resource-group "$RESOURCE_GROUP" \
            --name "$whatif_name" \
            --template-file "$MAIN_BICEP_FILE" \
            --parameters "$PARAMETER_FILE" \
            --result-format ResourceIdOnly 2>/dev/null || {
            
            log_info "Detailed what-if results saved to: whatif_result.json"
        }
        
    else
        log_error "❌ What-if analysis failed"
        log_info "What-if errors saved to: whatif_result.json"
        
        if [[ -f whatif_result.json ]]; then
            local error_message
            error_message=$(jq -r '.error.message // "Unknown what-if error"' whatif_result.json 2>/dev/null || echo "Could not parse what-if error")
            log_error "What-if error: $error_message"
        fi
        
        return 1
    fi
}

generate_validation_report() {
    log_step "Generating validation report"
    
    local report_file="validation_report_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Infrastructure Validation Report

**Date:** $(date)
**Environment:** $ENVIRONMENT
**Project:** $PROJECT_NAME
**Resource Group:** $RESOURCE_GROUP

## Validation Summary

### Template Files
- Main Template: \`$MAIN_BICEP_FILE\`
- Parameter File: \`$PARAMETER_FILE\`

### Validation Results
$(if [[ -f validation_result.json ]]; then echo "✅ ARM Template Validation: PASSED"; else echo "❌ ARM Template Validation: FAILED"; fi)
$(if [[ -f whatif_result.json ]]; then echo "✅ What-If Analysis: COMPLETED"; else echo "❌ What-If Analysis: FAILED"; fi)

### Resource Group Status
$(if check_resource_group_exists "$RESOURCE_GROUP" >/dev/null 2>&1; then echo "✅ Resource Group '$RESOURCE_GROUP' exists"; else echo "⚠️ Resource Group '$RESOURCE_GROUP' will be created"; fi)

### Generated Files
- Validation Results: \`validation_result.json\`
- What-If Results: \`whatif_result.json\`
- This Report: \`$report_file\`

## Next Steps

1. Review the what-if analysis results to understand what changes will be made
2. If validation passed, you can proceed with deployment using:
   \`\`\`bash
   ./deploy.sh $ENVIRONMENT
   \`\`\`
3. If validation failed, review the error messages and fix any issues before retrying

## Additional Information

For detailed analysis of validation or what-if results, examine the JSON files generated during this validation.

EOF

    log_success "Validation report generated: $report_file"
}

main() {
    init_script "Infrastructure Validation"
    
    # Main validation flow
    setup_validation
    validate_prerequisites
    
    local validation_passed=true
    
    # Run all validations
    if ! validate_bicep_syntax; then
        validation_passed=false
    fi
    
    if ! validate_parameter_file; then
        validation_passed=false
    fi
    
    # Only run Azure validations if resource group exists or can be checked
    if check_resource_group_exists "$RESOURCE_GROUP" >/dev/null 2>&1; then
        if ! run_template_validation; then
            validation_passed=false
        fi
        
        if ! run_what_if_analysis; then
            validation_passed=false
        fi
    else
        log_warning "Skipping Azure template validation and what-if analysis"
        log_warning "Resource group '$RESOURCE_GROUP' does not exist"
        log_info "These validations will run during deployment when the resource group is available"
    fi
    
    # Generate report regardless of validation results
    generate_validation_report
    
    # Final validation summary
    log_separator
    if [[ "$validation_passed" == "true" ]]; then
        log_success "🎉 All validations passed!"
        log_info "Your template is ready for deployment"
        echo
        log_info "To deploy this infrastructure, run:"
        log_info "  ./deploy.sh $ENVIRONMENT"
    else
        log_error "❌ Some validations failed"
        log_info "Please review the errors above and fix any issues before deployment"
        exit 1
    fi
}

# ===================================
# SCRIPT EXECUTION
# ===================================

# Show usage if help is requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Azure Infrastructure Validation Script"
    echo
    echo "Usage: $0 [environment]"
    echo
    echo "Parameters:"
    echo "  environment    Target environment (dev|prod). Default: dev"
    echo
    echo "Examples:"
    echo "  $0 dev         # Validate development environment"
    echo "  $0 prod        # Validate production environment"
    echo
    echo "What this script does:"
    echo "  • Validates Bicep syntax for all templates"
    echo "  • Checks parameter file completeness"
    echo "  • Runs Azure Resource Manager template validation"
    echo "  • Performs what-if analysis to preview changes"
    echo "  • Generates a comprehensive validation report"
    echo
    echo "Prerequisites:"
    echo "  • Azure CLI installed and configured"
    echo "  • Logged into Azure (az login)"
    echo "  • Read permissions on target subscription"
    exit 0
fi

# Run main function
main "$@"