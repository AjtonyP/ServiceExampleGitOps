#!/bin/bash
set -e

echo "======================================"
echo "Destroying ServiceExample MicroK8s Cluster"
echo "======================================"
echo ""
echo "WARNING: This will:"
echo "  - Destroy all deployed applications"
echo "  - Remove all data"
echo "  - Uninstall MicroK8s"
echo ""

read -p "Are you sure? (type 'yes' to confirm) " -r
echo ""

if [[ ! $REPLY == "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Remove MicroK8s
if command -v microk8s &> /dev/null; then
    echo "Removing MicroK8s..."
    sudo snap remove microk8s --purge
    echo "MicroK8s removed"
else
    echo "MicroK8s not installed"
fi

# Clean up kubeconfig
if [ -f ~/.kube/microk8s-config ]; then
    echo "Removing kubeconfig..."
    rm ~/.kube/microk8s-config
    echo "Kubeconfig removed"
fi

# Clean up Terraform state
if [ -f terraform.tfstate ]; then
    echo "Removing Terraform state..."
    rm -f terraform.tfstate terraform.tfstate.backup
    echo "Terraform state removed"
fi

echo ""
echo "======================================"
echo "Cleanup complete!"
echo "======================================"
