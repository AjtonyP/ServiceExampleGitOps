#!/bin/bash
set -e

# Ensure snap binaries are in PATH
export PATH=$PATH:/snap/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================"
echo "ServiceExample MicroK8s Setup"
echo "======================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed. Please install it first:"
    echo "   https://developer.hashicorp.com/terraform/install"
    exit 1
fi

if ! command -v snap &> /dev/null; then
    echo "ERROR: Snap is not installed. This script requires snap to install MicroK8s."
    exit 1
fi

echo "Prerequisites met"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo ""
echo "======================================"
echo "This will:"
echo "  - Install MicroK8s"
echo "  - Enable DNS, storage, and MetalLB"
echo "  - Install FluxCD"
echo "  - Deploy Longhorn storage"
echo "  - Deploy Prometheus + Grafana + Loki"
echo "  - Deploy ServiceExample application"
echo "======================================"
echo ""

read -p "Continue? (y/n) " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Apply Terraform
echo ""
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo ""
echo "======================================"
echo "Setup complete!"
echo "======================================"
echo ""

# Set KUBECONFIG for the current session
export KUBECONFIG=~/.kube/microk8s-config

# Add to shell profile if not already there
KUBECONFIG_EXPORT='export KUBECONFIG=~/.kube/microk8s-config'
PATH_EXPORT='export PATH=$PATH:/snap/bin'

# Add PATH for snap binaries if not already there
if ! grep -q "PATH.*snap/bin" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Snap binaries" >> ~/.bashrc
    echo "$PATH_EXPORT" >> ~/.bashrc
    echo "Added /snap/bin to PATH in ~/.bashrc"
fi

# Add KUBECONFIG if not already there
if ! grep -q "KUBECONFIG=.*microk8s-config" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# MicroK8s kubeconfig" >> ~/.bashrc
    echo "$KUBECONFIG_EXPORT" >> ~/.bashrc
    echo "Added KUBECONFIG to ~/.bashrc"
fi

echo "KUBECONFIG has been set to: $KUBECONFIG"
echo ""
echo "Next steps:"
echo ""
echo "1. Source your profile or start a new shell:"
echo "   source ~/.bashrc"
echo ""
echo "2. Wait for all pods to be ready (this may take 5-10 minutes):"
echo "   watch kubectl get pods -A"
echo ""
echo "3. Check Flux status:"
echo "   flux get all -A"
echo ""
echo "4. Access services:"
echo "   - ServiceExample: http://localhost:30080"
echo "   - Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo "     (admin/prom-operator)"
echo "   - Longhorn UI: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
echo ""
echo "5. View logs:"
echo "   kubectl logs -f -n flux-system -l app=source-controller"
echo ""
echo "NOTE: Run 'source ~/.bashrc' in your current shell to apply KUBECONFIG setting"
echo ""
