#!/bin/bash
set -e

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
echo "Next steps:"
echo ""
echo "1. Set your kubeconfig:"
echo "   export KUBECONFIG=~/.kube/microk8s-config"
echo ""
echo "2. Wait for all pods to be ready (this may take 5-10 minutes):"
echo "   watch microk8s kubectl get pods -A"
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
echo "   microk8s kubectl logs -f -n flux-system -l app=source-controller"
echo ""
