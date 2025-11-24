#!/bin/bash
# Quick script to set KUBECONFIG for MicroK8s cluster

export KUBECONFIG=~/.kube/microk8s-config

if [ ! -f "$KUBECONFIG" ]; then
    echo "ERROR: Kubeconfig not found at $KUBECONFIG"
    echo "Have you run terraform/setup.sh yet?"
    exit 1
fi

echo "KUBECONFIG set to: $KUBECONFIG"
echo ""
echo "You can now run flux and kubectl commands:"
echo "  flux get all -A"
echo "  kubectl get pods -A"
echo ""
echo "To make this permanent, add to your ~/.bashrc:"
echo "  echo 'export KUBECONFIG=~/.kube/microk8s-config' >> ~/.bashrc"
