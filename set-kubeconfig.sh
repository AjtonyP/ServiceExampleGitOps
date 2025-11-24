#!/bin/bash
# Quick script to set KUBECONFIG for MicroK8s cluster

# Ensure snap binaries are in PATH
export PATH=$PATH:/snap/bin

# Check if kubeconfig exists
if [ ! -f ~/.kube/microk8s-config ]; then
    echo "ERROR: MicroK8s not found. Have you run terraform/setup.sh yet?"
    exit 1
fi

export KUBECONFIG=~/.kube/microk8s-config

echo "✓ KUBECONFIG set to: $KUBECONFIG"
echo ""
echo "You can now run flux and kubectl commands:"
echo "  flux get all -A"
echo "  kubectl get pods -A"
echo ""
echo "To make this permanent in your current shell, run:"
echo "  source ~/.bashrc"
