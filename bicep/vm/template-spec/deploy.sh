#!/bin/bash
# ================================================================================
# Deploy Windows VM Template Spec to Azure
# ================================================================================
# This script creates or updates the Template Spec in Azure and optionally
# creates a deployment from it.

set -e

# Configuration
TEMPLATE_SPEC_NAME="windows-vm-simplified"
TEMPLATE_SPEC_RG="rg-template-specs"
TEMPLATE_SPEC_LOCATION="eastus"
TEMPLATE_SPEC_VERSION="1.0.0"
TEMPLATE_SPEC_DESCRIPTION="Simplified Windows VM deployment with Key Vault integration"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}Windows VM Template Spec Deployment${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged into Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✓ Logged in to subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})${NC}"
echo ""

# Create resource group for template spec
echo -e "${YELLOW}Creating resource group for Template Spec...${NC}"
az group create \
    --name "${TEMPLATE_SPEC_RG}" \
    --location "${TEMPLATE_SPEC_LOCATION}" \
    --output none

echo -e "${GREEN}✓ Resource group ready: ${TEMPLATE_SPEC_RG}${NC}"
echo ""

# Build the Bicep template
echo -e "${YELLOW}Building Bicep template...${NC}"
az bicep build --file main.bicep

echo -e "${GREEN}✓ Bicep template compiled successfully${NC}"
echo ""

# Create or update the template spec
echo -e "${YELLOW}Creating/updating Template Spec...${NC}"
az ts create \
    --name "${TEMPLATE_SPEC_NAME}" \
    --resource-group "${TEMPLATE_SPEC_RG}" \
    --location "${TEMPLATE_SPEC_LOCATION}" \
    --description "${TEMPLATE_SPEC_DESCRIPTION}" \
    --display-name "Windows VM - Simplified Deployment" \
    --version "${TEMPLATE_SPEC_VERSION}" \
    --template-file main.bicep \
    --ui-form-definition uiFormDefinition.json \
    --version-description "Initial release with Key Vault integration" \
    --tags "Type=TemplateSpec" "OS=Windows" "ManagedBy=ITOps"

echo -e "${GREEN}✓ Template Spec created/updated successfully${NC}"
echo ""

# Get Template Spec ID
TEMPLATE_SPEC_ID=$(az ts show \
    --name "${TEMPLATE_SPEC_NAME}" \
    --resource-group "${TEMPLATE_SPEC_RG}" \
    --version "${TEMPLATE_SPEC_VERSION}" \
    --query id -o tsv)

echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""
echo "Template Spec Details:"
echo "  Name: ${TEMPLATE_SPEC_NAME}"
echo "  Resource Group: ${TEMPLATE_SPEC_RG}"
echo "  Version: ${TEMPLATE_SPEC_VERSION}"
echo "  ID: ${TEMPLATE_SPEC_ID}"
echo ""
echo "Next Steps:"
echo "  1. Deploy via Azure Portal:"
echo "     Navigate to Template Specs → ${TEMPLATE_SPEC_NAME} → Deploy"
echo ""
echo "  2. Deploy via Azure CLI:"
echo "     az deployment sub create \\"
echo "       --location ${TEMPLATE_SPEC_LOCATION} \\"
echo "       --template-spec \"${TEMPLATE_SPEC_ID}\" \\"
echo "       --parameters main.bicepparam"
echo ""
echo "  3. View in Portal:"
echo "     https://portal.azure.com/#resource${TEMPLATE_SPEC_ID}"
echo ""
echo -e "${GREEN}================================================================================${NC}"
