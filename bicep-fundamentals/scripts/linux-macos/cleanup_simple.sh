#!/bin/bash

# ==============================================================================
# Simple Infrastructure Cleanup Script for Linux/macOS
# ==============================================================================
# This script deletes the Azure resource group and all its resources.
# 
# USAGE:
#   ./cleanup_simple.sh
#
# REQUIREMENTS:
#   - Azure CLI installed and logged in
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME="rgdev-workshop-bicep"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}[INFO] Starting Infrastructure Cleanup${NC}"
echo -e "${BLUE}[INFO] Date: $(date)${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}[ERROR] Azure CLI not found. Please install Azure CLI first.${NC}"
    exit 1
fi

# Check if logged into Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}[ERROR] Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

# Show current subscription
echo -e "${GREEN}[INFO] Current Azure subscription:${NC}"
az account show --query "{Name:name, SubscriptionId:id}" --output table
echo

# Check if resource group exists
if ! az group exists --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    echo -e "${YELLOW}[INFO] Resource group '$RESOURCE_GROUP_NAME' does not exist or has already been deleted.${NC}"
    echo -e "${GREEN}[SUCCESS] No resources to clean up!${NC}"
    exit 0
fi

# Show resources that will be deleted
echo -e "${YELLOW}[INFO] Resources in '$RESOURCE_GROUP_NAME' that will be deleted:${NC}"
az resource list --resource-group "$RESOURCE_GROUP_NAME" --output table || true
echo

# Confirmation
echo -e "${RED}⚠️  WARNING: This will permanently delete ALL resources in the resource group!${NC}"
echo -e "${RED}⚠️  This action CANNOT be undone!${NC}"
echo
read -p "Are you sure you want to delete the resource group '$RESOURCE_GROUP_NAME'? (yes/no): " -r
echo

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}[INFO] Deleting resource group: $RESOURCE_GROUP_NAME${NC}"
    echo -e "${YELLOW}[INFO] This may take several minutes...${NC}"
    
    if az group delete --name "$RESOURCE_GROUP_NAME" --yes; then
        echo
        echo -e "${GREEN}[SUCCESS] Resource group '$RESOURCE_GROUP_NAME' has been deleted successfully!${NC}"
        echo -e "${GREEN}[SUCCESS] All workshop resources have been cleaned up!${NC}"
        echo
        echo -e "${BLUE}[INFO] 🎉 Workshop cleanup completed!${NC}"
    else
        echo
        echo -e "${RED}[ERROR] Failed to delete resource group. Please check the error messages above.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[INFO] Operation cancelled by user.${NC}"
    exit 0
fi