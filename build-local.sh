#!/bin/bash
set -euo pipefail

# BlueOx OS - Local Build and Sign Script
# This script builds and signs container images locally without relying on GitHub Actions

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}BlueOx OS - Local Build Script${NC}"
echo "=================================="

# Configuration
RECIPE_FILE="${1:-recipes/blueox.yml}"
COSIGN_KEY_PATH="${HOME}/.ssh/blueox-os/cosign.key"
COSIGN_PUB_PATH="${HOME}/.ssh/blueox-os/cosign.pub"
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="${NAMESPACE:-$(whoami)}"
NAMESPACE=$(echo "$NAMESPACE" | tr '[:upper:]' '[:lower:]')
REPO_NAME="blueox-os"

# Validate cosign keys exist
if [[ ! -f "$COSIGN_KEY_PATH" ]]; then
    echo -e "${RED}Error: Cosign private key not found at $COSIGN_KEY_PATH${NC}"
    exit 1
fi

if [[ ! -f "$COSIGN_PUB_PATH" ]]; then
    echo -e "${YELLOW}Warning: Cosign public key not found at $COSIGN_PUB_PATH${NC}"
fi

# Validate recipe file exists
if [[ ! -f "$RECIPE_FILE" ]]; then
    echo -e "${RED}Error: Recipe file not found at $RECIPE_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  Recipe: $RECIPE_FILE"
echo "  Cosign Key: $COSIGN_KEY_PATH"
echo "  Registry: $REGISTRY"
echo "  Namespace: $NAMESPACE"
echo "  Repository: $REPO_NAME"
echo ""

# Export cosign key for bluebuild to use
export COSIGN_KEY="$COSIGN_KEY_PATH"

# Prompt for cosign password if not already set
if [[ -z "${COSIGN_PASSWORD:-}" ]]; then
    echo -e "${YELLOW}Enter cosign password (or press Enter if no password):${NC}"
    read -s COSIGN_PASSWORD
    export COSIGN_PASSWORD
    echo ""
fi

# Build the image
echo -e "${GREEN}Building image...${NC}"
bluebuild build \
    --build-driver podman \
    --signing-driver cosign \
    "$RECIPE_FILE"

# Calculate tags
DATE_TAG=$(date +%Y%m%d)
SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

echo ""
echo -e "${GREEN}Build completed successfully!${NC}"
echo ""
echo "Built images should be tagged as:"
echo "  - ${REGISTRY}/${NAMESPACE}/${REPO_NAME}:latest"
echo "  - ${REGISTRY}/${NAMESPACE}/${REPO_NAME}:${DATE_TAG}"
echo "  - ${REGISTRY}/${NAMESPACE}/${REPO_NAME}:43"
echo "  - ${REGISTRY}/${NAMESPACE}/${REPO_NAME}:${DATE_TAG}-43"
echo "  - ${REGISTRY}/${NAMESPACE}/${REPO_NAME}:${SHORT_SHA}-43"
echo ""
echo "To push to registry, add these flags to bluebuild build:"
echo "  --push --registry $REGISTRY --username <username> --password <password>"
echo ""
echo "To rebase your system to the locally built image:"
echo "  rpm-ostree rebase ostree-image-signed:docker://${REGISTRY}/${NAMESPACE}/${REPO_NAME}:latest"
