#!/bin/bash

# ===================================
# AZURE INFRASTRUCTURE CLEANUP SCRIPT
# ===================================
# Safely removes all resources created by the infrastructure deployment
# With multiple confirmation levels and safety checks
#
# Usage: ./cleanup.sh [environment] [force]
#   environment: dev|prod (default: dev)
#   force: skip confirmation prompts (use with caution)
#
# Examples:
#   ./cleanup.sh dev
#   ./cleanup.sh prod  
#   ./cleanup.sh dev force

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
# CLEANUP CONFIGURATION
# ===================================

readonly PARAMETERS_DIR="$PROJECT_ROOT/parameters"
readonly DEFAULT_ENVIRONMENT="dev"
readonly CLEANUP_TIMEOUT=1800  # 30 minutes

# ===================================
# SCRIPT VARIABLES
# ===================================

ENVIRONMENT="${1:-$DEFAULT_ENVIRONMENT}"
FORCE_MODE="${2:-false}"
PARAMETER_FILE=""
RESOURCE_GROUP=""
PROJECT_NAME=""
RESOURCES_TO_DELETE=()

# ===================================
# MAIN FUNCTIONS
# ===================================

setup_cleanup() {
    log_step "Setting up cleanup configuration"
    
    # Validate environment parameter
    if ! validate_environment "$ENVIRONMENT"; then
        log_error "Please specify a valid environment: dev or prod"
        exit 1
    fi
    
    # Set parameter file path
    PARAMETER_FILE="$PARAMETERS_DIR/main.$ENVIRONMENT.bicepparam"
    
    # Validate parameter file exists
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
    
    log_success "Cleanup configuration set up"
    log_info "Environment: $ENVIRONMENT"
    log_info "Resource Group: $RESOURCE_GROUP"
    log_info "Project Name: $PROJECT_NAME"
    log_info "Parameter File: $PARAMETER_FILE"
}

validate_cleanup_prerequisites() {
    log_step "Validating prerequisites"
    
    # Check Azure CLI and login status
    check_azure_cli
    check_azure_login
    
    # Check if resource group exists
    if ! check_resource_group_exists "$RESOURCE_GROUP"; then
        log_warning "Resource group '$RESOURCE_GROUP' does not exist"
        log_info "Nothing to clean up"
        exit 0
    fi
    
    log_success "Prerequisites validation completed"
}

analyze_resources() {
    log_step "Analyzing resources to be deleted"
    
    # Get all resources in the resource group that belong to this project
    log_info "Searching for project resources..."
    
    # Try to get resources by tags first
    local tagged_resources
    tagged_resources=$(az resource list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?tags.project=='$PROJECT_NAME' && tags.environment=='$ENVIRONMENT'].{Name:name, Type:type, Id:id}" \
        --output json 2>/dev/null || echo "[]")
    
    if [[ "$tagged_resources" != "[]" ]] && [[ $(echo "$tagged_resources" | jq length) -gt 0 ]]; then
        log_info "Found $(echo "$tagged_resources" | jq length) resources with project tags"
        echo "$tagged_resources" | jq -r '.[] | "  • \(.Name) (\(.Type))"'
    else
        log_warning "No resources found with project tags, analyzing by naming convention..."
        
        # Fallback: get resources by naming convention
        local all_resources
        all_resources=$(az resource list \
            --resource-group "$RESOURCE_GROUP" \
            --query "[].{Name:name, Type:type, Id:id}" \
            --output json 2>/dev/null || echo "[]")
        
        # Filter resources that match our naming patterns
        local project_resources
        project_resources=$(echo "$all_resources" | jq --arg project "$PROJECT_NAME" --arg env "$ENVIRONMENT" '
            [.[] | select(
                (.Name | contains($project)) and
                (.Name | contains($env))
            )]')
        
        if [[ $(echo "$project_resources" | jq length) -gt 0 ]]; then
            log_info "Found $(echo "$project_resources" | jq length) resources matching naming convention"
            echo "$project_resources" | jq -r '.[] | "  • \(.Name) (\(.Type))"'
            tagged_resources="$project_resources"
        else
            log_warning "No resources found matching project naming convention"
            
            if [[ "$FORCE_MODE" != "force" ]]; then
                if confirm_action "Show all resources in the resource group for manual selection?"; then
                    show_all_resources_for_selection
                else
                    log_info "Cleanup cancelled by user"
                    exit 0
                fi
            else
                log_error "No resources found to delete in force mode"
                exit 1
            fi
        fi
    fi
    
    # Store resources for deletion
    echo "$tagged_resources" > resources_to_delete.json
    
    # Check for special resources that need careful handling
    check_for_special_resources "$tagged_resources"
}

show_all_resources_for_selection() {
    log_info "All resources in resource group '$RESOURCE_GROUP':"
    
    az resource list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[].{Name:name, Type:type, Location:location}" \
        --output table
    
    echo
    log_warning "⚠️  The above resources will be deleted if you continue"
    log_warning "⚠️  This includes ALL resources in the resource group, not just project resources"
    
    if [[ "$FORCE_MODE" != "force" ]]; then
        if ! confirm_action "Are you sure you want to delete ALL resources in this resource group?"; then
            log_info "Cleanup cancelled by user"
            exit 0
        fi
    fi
}

check_for_special_resources() {
    local resources_json="$1"
    
    # Check for Key Vaults with purge protection
    local key_vaults
    key_vaults=$(echo "$resources_json" | jq -r '.[] | select(.Type == "Microsoft.KeyVault/vaults") | .Name' 2>/dev/null || echo "")
    
    if [[ -n "$key_vaults" ]]; then
        log_warning "Found Key Vault(s) that may have purge protection enabled:"
        echo "$key_vaults" | while read -r kv_name; do
            if [[ -n "$kv_name" ]]; then
                echo "  • $kv_name"
                
                # Check purge protection status
                local purge_protected
                purge_protected=$(az keyvault show \
                    --name "$kv_name" \
                    --query "properties.enablePurgeProtection" \
                    --output tsv 2>/dev/null || echo "unknown")
                
                if [[ "$purge_protected" == "true" ]]; then
                    log_warning "    ⚠️  Purge protection is ENABLED - vault will be soft deleted"
                    log_info "    ℹ️  To permanently delete: az keyvault purge --name $kv_name --location <location>"
                fi
            fi
        done
    fi
    
    # Check for SQL Servers with databases
    local sql_servers
    sql_servers=$(echo "$resources_json" | jq -r '.[] | select(.Type == "Microsoft.Sql/servers") | .Name' 2>/dev/null || echo "")
    
    if [[ -n "$sql_servers" ]]; then
        log_warning "Found SQL Server(s) with potential data loss:"
        echo "$sql_servers" | while read -r server_name; do
            if [[ -n "$server_name" ]]; then
                echo "  • $server_name"
                log_warning "    ⚠️  All databases and data will be permanently deleted"
            fi
        done
    fi
    
    # Check for Storage Accounts with data
    local storage_accounts
    storage_accounts=$(echo "$resources_json" | jq -r '.[] | select(.Type == "Microsoft.Storage/storageAccounts") | .Name' 2>/dev/null || echo "")
    
    if [[ -n "$storage_accounts" ]]; then
        log_warning "Found Storage Account(s) with potential data loss:"
        echo "$storage_accounts" | while read -r storage_name; do
            if [[ -n "$storage_name" ]]; then
                echo "  • $storage_name"
                log_warning "    ⚠️  All blobs, files, and data will be permanently deleted"
            fi
        done
    fi
}

confirm_cleanup() {
    if [[ "$FORCE_MODE" == "force" ]]; then
        log_warning "Running in FORCE MODE - skipping confirmations"
        return 0
    fi
    
    log_step "Cleanup Confirmation"
    
    # Show summary
    local resource_count
    resource_count=$(jq length resources_to_delete.json 2>/dev/null || echo "0")
    
    log_warning "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
    echo
    log_info "You are about to DELETE the following:"
    log_info "  • Environment: $ENVIRONMENT"
    log_info "  • Resource Group: $RESOURCE_GROUP"
    log_info "  • Resources: $resource_count items"
    log_info "  • Project: $PROJECT_NAME"
    echo
    log_error "🚨 THIS ACTION CANNOT BE UNDONE 🚨"
    log_error "🚨 ALL DATA WILL BE PERMANENTLY LOST 🚨"
    
    echo
    
    # First confirmation
    if ! confirm_action "Do you understand that this will permanently delete all resources and data?"; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    # Second confirmation with environment name
    local env_confirmation
    env_confirmation=$(get_user_input "Type the environment name '$ENVIRONMENT' to confirm deletion")
    
    if [[ "$env_confirmation" != "$ENVIRONMENT" ]]; then
        log_error "Environment confirmation failed. Expected: '$ENVIRONMENT', Got: '$env_confirmation'"
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    # Final confirmation
    if ! confirm_action "Last chance: Are you absolutely sure you want to proceed with deletion?"; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    log_warning "Cleanup confirmed. Proceeding with deletion..."
}

backup_resource_configuration() {
    log_step "Creating backup of resource configurations"
    
    local backup_dir="backup_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Backing up resource configurations to: $backup_dir"
    
    # Backup resource group information
    az group show --name "$RESOURCE_GROUP" > "$backup_dir/resource_group.json" 2>/dev/null || true
    
    # Backup individual resource configurations
    if [[ -f resources_to_delete.json ]]; then
        cp resources_to_delete.json "$backup_dir/resources_list.json"
        
        jq -r '.[].Id' resources_to_delete.json 2>/dev/null | while read -r resource_id; do
            if [[ -n "$resource_id" ]]; then
                local resource_name
                resource_name=$(basename "$resource_id")
                
                log_info "Backing up configuration for: $resource_name"
                az resource show --ids "$resource_id" > "$backup_dir/${resource_name}.json" 2>/dev/null || true
            fi
        done
    fi
    
    # Backup parameter file
    if [[ -f "$PARAMETER_FILE" ]]; then
        cp "$PARAMETER_FILE" "$backup_dir/parameters.bicepparam"
    fi
    
    log_success "Resource configurations backed up to: $backup_dir"
    log_info "Keep this backup to restore resources if needed"
}

delete_resources() {
    log_step "Deleting resources"
    
    if [[ ! -f resources_to_delete.json ]]; then
        log_error "No resources list found"
        exit 1
    fi
    
    local resource_count
    resource_count=$(jq length resources_to_delete.json)
    
    if [[ "$resource_count" -eq 0 ]]; then
        log_info "No resources to delete"
        return 0
    fi
    
    log_info "Deleting $resource_count resources..."
    
    # Method 1: Try to delete individual resources first (for better control)
    local deletion_errors=0
    
    jq -r '.[] | "\(.Id)|\(.Name)|\(.Type)"' resources_to_delete.json | while IFS='|' read -r resource_id resource_name resource_type; do
        if [[ -n "$resource_id" ]]; then
            log_info "Deleting: $resource_name ($resource_type)"
            
            if az resource delete --ids "$resource_id" --verbose 2>/dev/null; then
                log_success "  ✅ Deleted: $resource_name"
            else
                log_warning "  ⚠️  Failed to delete: $resource_name (will retry with resource group deletion)"
                ((deletion_errors++))
            fi
        fi
    done
    
    # Method 2: If individual deletions failed, try resource group deletion
    if [[ $deletion_errors -gt 0 ]]; then
        log_warning "Some individual resource deletions failed"
        
        if confirm_action "Delete the entire resource group to ensure complete cleanup?"; then
            delete_resource_group
        else
            log_warning "Some resources may remain. Check the resource group manually."
        fi
    else
        log_success "All individual resources deleted successfully"
        
        # Check if resource group is empty and offer to delete it
        local remaining_resources
        remaining_resources=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" --output tsv 2>/dev/null || echo "0")
        
        if [[ "$remaining_resources" -eq 0 ]]; then
            if [[ "$FORCE_MODE" == "force" ]] || confirm_action "Resource group is now empty. Delete the resource group as well?"; then
                delete_resource_group
            fi
        else
            log_info "Resource group contains $remaining_resources other resources and will be kept"
        fi
    fi
}

delete_resource_group() {
    log_info "Deleting resource group: $RESOURCE_GROUP"
    log_warning "This will delete ALL resources in the resource group"
    
    if az group delete \
        --name "$RESOURCE_GROUP" \
        --yes \
        --no-wait; then
        
        log_success "Resource group deletion initiated"
        log_info "Deletion is running in the background"
        log_info "You can monitor progress with:"
        log_info "  az group show --name '$RESOURCE_GROUP'"
    else
        log_error "Failed to initiate resource group deletion"
        return 1
    fi
}

verify_cleanup() {
    log_step "Verifying cleanup completion"
    
    # Check if resource group still exists
    if check_resource_group_exists "$RESOURCE_GROUP" >/dev/null 2>&1; then
        local remaining_resources
        remaining_resources=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" --output tsv 2>/dev/null || echo "unknown")
        
        if [[ "$remaining_resources" == "0" ]]; then
            log_success "✅ Resource group exists but is empty"
        else
            log_warning "⚠️  Resource group still contains $remaining_resources resources"
            log_info "Listing remaining resources:"
            az resource list \
                --resource-group "$RESOURCE_GROUP" \
                --query "[].{Name:name, Type:type}" \
                --output table 2>/dev/null || true
        fi
    else
        log_success "✅ Resource group has been completely deleted"
    fi
}

cleanup_temp_files() {
    # Clean up temporary files
    rm -f resources_to_delete.json 2>/dev/null || true
}

main() {
    init_script "Infrastructure Cleanup"
    
    # Set up cleanup on exit
    trap cleanup_temp_files EXIT
    
    # Show warning for production environment
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log_error "🚨 WARNING: PRODUCTION ENVIRONMENT DETECTED 🚨"
        log_warning "You are about to delete PRODUCTION resources!"
        
        if [[ "$FORCE_MODE" != "force" ]]; then
            if ! confirm_action "Are you sure you want to delete PRODUCTION resources?" "false"; then
                log_info "Production cleanup cancelled - good choice!"
                exit 0
            fi
        fi
    fi
    
    # Main cleanup flow
    setup_cleanup
    validate_cleanup_prerequisites
    analyze_resources
    confirm_cleanup
    backup_resource_configuration
    delete_resources
    verify_cleanup
    
    log_success "🎉 Cleanup completed!"
    
    # Final summary
    log_separator
    log_info "📋 Cleanup Summary:"
    log_info "  • Environment: $ENVIRONMENT"
    log_info "  • Resource Group: $RESOURCE_GROUP"
    log_info "  • Project: $PROJECT_NAME"
    log_info "  • Backup Created: Yes (check backup_* directories)"
    
    echo
    log_info "Next steps:"
    log_info "  • Review the backup files if you need to restore anything"
    log_info "  • Update any external references to the deleted resources"
    log_info "  • Consider removing the resource group if it's now empty"
}

# ===================================
# SCRIPT EXECUTION
# ===================================

# Show usage if help is requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Azure Infrastructure Cleanup Script"
    echo
    echo "Usage: $0 [environment] [force]"
    echo
    echo "Parameters:"
    echo "  environment    Target environment (dev|prod). Default: dev"
    echo "  force          Skip confirmation prompts (use with extreme caution)"
    echo
    echo "Examples:"
    echo "  $0 dev         # Clean up development environment (with confirmations)"
    echo "  $0 prod        # Clean up production environment (with confirmations)"
    echo "  $0 dev force   # Clean up development environment (no confirmations)"
    echo
    echo "⚠️  WARNING: This script permanently deletes Azure resources!"
    echo "⚠️  ALL DATA WILL BE LOST! Use with extreme caution!"
    echo
    echo "Safety features:"
    echo "  • Multiple confirmation prompts"
    echo "  • Resource configuration backup before deletion"
    echo "  • Special handling for Key Vaults and databases"
    echo "  • Resource filtering by project tags or naming convention"
    echo
    echo "Prerequisites:"
    echo "  • Azure CLI installed and configured"
    echo "  • Logged into Azure (az login)"
    echo "  • Appropriate permissions to delete resources"
    exit 0
fi

# Run main function
main "$@"