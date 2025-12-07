#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}MongoDB Atlas Workshop - Setup Helper${NC}"
echo "-------------------------------------"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}[MISSING] $1 could not be found.${NC}"
        return 1
    else
        echo -e "${GREEN}[OK] $1 is installed.${NC}"
        return 0
    fi
}

# Function to install via Homebrew
install_brew() {
    if command -v brew &> /dev/null; then
        echo -e "${YELLOW}Attempting to install $1 via Homebrew...${NC}"
        brew install "$1"
    else
        echo -e "${RED}Homebrew not found. Please install $1 manually.${NC}"
    fi
}

# 1. Check Prerequisites
echo -e "\nChecking Prerequisites..."
MISSING_TOOLS=0

# Check Terraform
if ! check_command "terraform"; then
    install_brew "terraform"
    MISSING_TOOLS=1
fi

# Check gcloud
if ! check_command "gcloud"; then
    echo -e "${YELLOW}Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install${NC}"
    MISSING_TOOLS=1
fi

# Check kubectl (Optional but recommended)
if ! check_command "kubectl"; then
    install_brew "kubectl"
fi

if [ $MISSING_TOOLS -eq 1 ] && ! command -v terraform &> /dev/null; then
    echo -e "${RED}Some required tools are missing and could not be auto-installed. Please install them and run this script again.${NC}"
    exit 1
fi

# 2. Configure Credentials
echo -e "\nConfiguring Credentials..."
echo "Please enter your MongoDB Atlas API details."

read -p "Atlas Public Key: " ATLAS_PUBLIC_KEY
read -s -p "Atlas Private Key: " ATLAS_PRIVATE_KEY
echo ""
read -p "Atlas Organization ID: " ATLAS_ORG_ID
read -p "Google Cloud Project ID: " GCP_PROJECT_ID
read -s -p "GitHub Token (for Backstage): " GITHUB_TOKEN
echo ""

# 2.5 Google Cloud Auth
echo -e "\nConfiguring Google Cloud Authentication..."
echo "Checking if you are already authenticated..."
if ! gcloud auth application-default print-access-token &> /dev/null; then
    echo "Authenticating with Google Cloud..."
    gcloud auth application-default login
else
    echo -e "${GREEN}[OK] Already authenticated with Google Cloud.${NC}"
fi

# Export variables for the current session (if sourced) or write to a .env file
echo -e "\nWriting credentials to .env file..."
cat <<EOF > .env
export TF_VAR_atlas_public_key="$ATLAS_PUBLIC_KEY"
export TF_VAR_atlas_private_key="$ATLAS_PRIVATE_KEY"
export TF_VAR_atlas_org_id="$ATLAS_ORG_ID"
export TF_VAR_gcp_project_id="$GCP_PROJECT_ID"
export GITHUB_TOKEN="$GITHUB_TOKEN"
EOF

echo -e "${GREEN}Credentials saved to .env${NC}"
echo -e "${YELLOW}Run 'source .env' to load them into your shell.${NC}"

# 3. Terraform Init
echo -e "\nInitializing Terraform..."
if [ -d "../terraform" ]; then
    cd ../terraform
    terraform init
    echo -e "${GREEN}Terraform initialized successfully!${NC}"
    cd ../scripts
else
    echo -e "${RED}Terraform directory not found relative to script location.${NC}"
fi

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "To start the demo:"
echo "1. Run: source .env"
echo "2. Navigate to terraform directory: cd ../terraform"
echo "3. Run: terraform apply"
