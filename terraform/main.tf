terraform {
  required_version = ">= 1.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Install MicroK8s
resource "null_resource" "install_microk8s" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v microk8s &> /dev/null; then
        echo "Installing MicroK8s..."
        sudo snap install microk8s --classic --channel=${var.microk8s_channel}
        sudo usermod -a -G microk8s $USER || true
        sudo chown -f -R $USER ~/.kube || true
        echo "MicroK8s installed. You may need to re-login or run 'newgrp microk8s' for group permissions."
      else
        echo "MicroK8s already installed"
      fi
    EOT
  }
}

# Wait for MicroK8s to be ready
resource "null_resource" "wait_for_microk8s" {
  depends_on = [null_resource.install_microk8s]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for MicroK8s to be ready..."
      # First ensure MicroK8s is started
      sudo microk8s start || true
      sleep 5
      # Wait for it to be ready
      timeout 300 bash -c 'until sudo microk8s status --wait-ready; do sleep 5; done'
    EOT
  }
}

# Enable required MicroK8s addons
resource "null_resource" "enable_addons" {
  depends_on = [null_resource.wait_for_microk8s]
  
  for_each = toset(var.microk8s_addons)
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Enabling addon: ${each.value}"
      sudo microk8s enable ${each.value}
    EOT
  }
}

# Wait for CoreDNS to be ready
resource "null_resource" "wait_for_coredns" {
  depends_on = [null_resource.enable_addons]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for CoreDNS to be ready..."
      sudo microk8s kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=300s
    EOT
  }
}

# Generate kubeconfig
resource "null_resource" "generate_kubeconfig" {
  depends_on = [null_resource.wait_for_coredns]
  
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${var.kubeconfig_dir}
      sudo microk8s config > ${var.kubeconfig_path}
      chmod 600 ${var.kubeconfig_path}
      echo "Kubeconfig saved to ${var.kubeconfig_path}"
    EOT
  }
}

# Install FluxCD
resource "null_resource" "install_flux_cli" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v flux &> /dev/null; then
        echo "Installing Flux CLI..."
        curl -s https://fluxcd.io/install.sh | sudo bash
      else
        echo "Flux CLI already installed"
      fi
    EOT
  }
}

# Bootstrap FluxCD
resource "null_resource" "bootstrap_flux" {
  depends_on = [
    null_resource.generate_kubeconfig,
    null_resource.install_flux_cli
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      # Check if Flux CRDs are already installed
      if sudo microk8s kubectl get crd gitrepositories.source.toolkit.fluxcd.io 2>/dev/null | grep -q gitrepositories; then
        echo "Flux already bootstrapped"
        exit 0
      fi
      
      echo "Bootstrapping Flux..."
      
      # Install Flux without GitHub integration (local setup)
      # Only installing core components - no image automation
      flux install \
        --namespace=flux-system \
        --network-policy=false
      
      # Wait for Flux to be ready
      echo "Waiting for Flux controllers to be ready..."
      sudo microk8s kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s
      sudo microk8s kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s
      sudo microk8s kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=300s
      
      # Wait for CRDs to be established
      echo "Waiting for Flux CRDs to be ready..."
      sleep 10
      sudo microk8s kubectl wait --for condition=established --timeout=60s crd/gitrepositories.source.toolkit.fluxcd.io
      sudo microk8s kubectl wait --for condition=established --timeout=60s crd/helmrepositories.source.toolkit.fluxcd.io
      sudo microk8s kubectl wait --for condition=established --timeout=60s crd/helmreleases.helm.toolkit.fluxcd.io
      sudo microk8s kubectl wait --for condition=established --timeout=60s crd/kustomizations.kustomize.toolkit.fluxcd.io
      
      echo "Flux installed successfully"
    EOT
  }
}

# Apply GitOps configuration
resource "null_resource" "apply_gitops_config" {
  depends_on = [null_resource.bootstrap_flux]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "Applying GitOps configuration..."
      
      # Verify CRDs are ready
      echo "Verifying Flux CRDs..."
      sudo microk8s kubectl get crd gitrepositories.source.toolkit.fluxcd.io
      sudo microk8s kubectl get crd helmrepositories.source.toolkit.fluxcd.io
      
      # Apply GitRepository and HelmRepository sources
      echo "Applying sources..."
      sudo microk8s kubectl apply -f ${path.module}/../flux/sources/
      
      # Wait for sources to sync
      echo "Waiting for sources to sync..."
      sleep 15
      
      # Apply infrastructure configs (Longhorn, monitoring) using kustomize
      echo "Applying infrastructure..."
      sudo microk8s kubectl apply -k ${path.module}/../flux/infrastructure/
      
      # Wait a bit
      sleep 5
      
      # Apply application configs using kustomize
      echo "Applying applications..."
      sudo microk8s kubectl apply -k ${path.module}/../flux/apps/
      
      echo "GitOps configuration applied"
    EOT
  }
}

# Output cluster info
resource "null_resource" "cluster_info" {
  depends_on = [null_resource.apply_gitops_config]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "=========================================="
      echo "MicroK8s cluster is ready!"
      echo "=========================================="
      echo "Kubeconfig: ${var.kubeconfig_path}"
      echo ""
      echo "To use kubectl with this cluster:"
      echo "  export KUBECONFIG=${var.kubeconfig_path}"
      echo "  or use: microk8s kubectl"
      echo ""
      echo "To check Flux status:"
      echo "  flux get all -A"
      echo ""
      echo "To access Grafana (once deployed):"
      echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
      echo "  Default credentials: admin/prom-operator"
      echo "=========================================="
    EOT
  }
}
