#!/bin/bash

# Retail Shopping Assistant Helm Deployment Script
# Supports both Kubernetes and OpenShift platforms

set -e

# Default values
NAMESPACE="retail-assistant"
RELEASE_NAME="retail-assistant"
PLATFORM="kubernetes"
ENABLE_LOCAL_NIM="false"
NGC_API_KEY=""
DRY_RUN="false"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy the Retail Shopping Assistant using Helm

OPTIONS:
    -n, --namespace NAMESPACE       Kubernetes namespace (default: retail-assistant)
    -r, --release RELEASE_NAME      Helm release name (default: retail-assistant)
    -p, --platform PLATFORM        Platform type: kubernetes|openshift (default: kubernetes)
    -g, --gpu                       Enable local NIM deployment (requires GPUs)
    -k, --api-key NGC_API_KEY       NVIDIA NGC API key (required)
    -d, --dry-run                   Perform a dry run without installing
    -h, --help                      Show this help message

EXAMPLES:
    # Deploy on Kubernetes with cloud NIM
    $0 --platform kubernetes --api-key YOUR_NGC_API_KEY

    # Deploy on OpenShift with cloud NIM
    $0 --platform openshift --api-key YOUR_NGC_API_KEY

    # Deploy on Kubernetes with local NIM (requires GPUs)
    $0 --platform kubernetes --gpu --api-key YOUR_NGC_API_KEY

    # Dry run deployment
    $0 --platform kubernetes --api-key YOUR_NGC_API_KEY --dry-run

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -g|--gpu)
            ENABLE_LOCAL_NIM="true"
            shift
            ;;
        -k|--api-key)
            NGC_API_KEY="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$NGC_API_KEY" ]]; then
    print_error "NGC API key is required. Use --api-key option."
    exit 1
fi

if [[ "$PLATFORM" != "kubernetes" && "$PLATFORM" != "openshift" ]]; then
    print_error "Platform must be either 'kubernetes' or 'openshift'"
    exit 1
fi

# Check if kubectl/oc is available
if [[ "$PLATFORM" == "openshift" ]]; then
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) is required but not installed"
        exit 1
    fi
    CLI_CMD="oc"
else
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required but not installed"
        exit 1
    fi
    CLI_CMD="kubectl"
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "Helm is required but not installed"
    exit 1
fi

print_status "Starting deployment with the following configuration:"
echo "  Platform: $PLATFORM"
echo "  Namespace: $NAMESPACE"
echo "  Release Name: $RELEASE_NAME"
echo "  Local NIM: $ENABLE_LOCAL_NIM"
echo "  Dry Run: $DRY_RUN"

# Create namespace if it doesn't exist
if [[ "$DRY_RUN" == "false" ]]; then
    if ! $CLI_CMD get namespace "$NAMESPACE" &> /dev/null; then
        print_status "Creating namespace: $NAMESPACE"
        $CLI_CMD create namespace "$NAMESPACE"
    else
        print_status "Namespace $NAMESPACE already exists"
    fi
fi

# Prepare Helm values
VALUES_FILES=()
VALUES_FILES+=("values.yaml")

# Add platform-specific values
if [[ "$PLATFORM" == "openshift" ]]; then
    VALUES_FILES+=("values-openshift.yaml")
else
    VALUES_FILES+=("values-kubernetes.yaml")
fi

# Add local NIM values if enabled
if [[ "$ENABLE_LOCAL_NIM" == "true" ]]; then
    VALUES_FILES+=("values-local-nim.yaml")
    print_warning "Local NIM deployment requires GPU nodes with NVIDIA GPU Operator installed"
fi

# Build Helm command
HELM_CMD="helm"
if [[ "$DRY_RUN" == "true" ]]; then
    HELM_CMD="$HELM_CMD --dry-run --debug"
fi

HELM_CMD="$HELM_CMD upgrade --install $RELEASE_NAME . --namespace $NAMESPACE --create-namespace"

# Add values files
for values_file in "${VALUES_FILES[@]}"; do
    HELM_CMD="$HELM_CMD --values $values_file"
done

# Add API key
HELM_CMD="$HELM_CMD --set env.ngcApiKey=$NGC_API_KEY"
HELM_CMD="$HELM_CMD --set env.llmApiKey=$NGC_API_KEY"
HELM_CMD="$HELM_CMD --set env.embedApiKey=$NGC_API_KEY"
HELM_CMD="$HELM_CMD --set env.railApiKey=$NGC_API_KEY"

# Execute Helm command
print_status "Executing Helm deployment..."
echo "Command: $HELM_CMD"

if eval "$HELM_CMD"; then
    if [[ "$DRY_RUN" == "false" ]]; then
        print_success "Deployment completed successfully!"
        
        print_status "Checking deployment status..."
        $CLI_CMD get pods -n "$NAMESPACE"
        
        if [[ "$PLATFORM" == "openshift" ]]; then
            print_status "Getting OpenShift route..."
            $CLI_CMD get route -n "$NAMESPACE"
        else
            print_status "Getting Kubernetes services..."
            $CLI_CMD get svc -n "$NAMESPACE"
        fi
        
        print_success "Retail Shopping Assistant is now deployed!"
        print_status "It may take a few minutes for all services to be ready."
    else
        print_success "Dry run completed successfully!"
    fi
else
    print_error "Deployment failed!"
    exit 1
fi