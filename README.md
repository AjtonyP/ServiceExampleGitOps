# ServiceExample GitOps Repository

This repository contains the GitOps configuration for deploying ServiceExample application on a local MicroK8s cluster using FluxCD.

## Overview

This setup provides a complete local Kubernetes development environment with:

- **MicroK8s**: Lightweight Kubernetes cluster
- **FluxCD**: GitOps continuous delivery
- **Longhorn**: Distributed storage system
- **Prometheus Stack**: Metrics collection and alerting
- **Grafana**: Monitoring dashboards
- **Loki**: Log aggregation
- **ServiceExample**: Your .NET application with MongoDB, Redis, and NATS

## Prerequisites

- **Operating System**: Ubuntu Linux
- **Terraform**: >= 1.0 ([Install](https://developer.hashicorp.com/terraform/install))
- **Snap**: For MicroK8s installation
- **Git**: For repository management
- **Minimum Resources**:
  - 4 CPU cores
  - 8GB RAM
  - 20GB free disk space

## Quick Start

### 1. Run Setup

```bash
cd terraform
./setup.sh
```

This script will:

1. Install MicroK8s
2. Enable required addons (DNS, storage, MetalLB)
3. Install FluxCD
4. Bootstrap GitOps configuration
5. Deploy all infrastructure and applications
6. **Automatically configure KUBECONFIG** in your `~/.bashrc`

### 2. Configure Your Shell

After running `setup.sh`, apply the KUBECONFIG setting:

```bash
# Option 1: Source your profile (for current shell)
source ~/.bashrc

# Option 2: Use the helper script
source ../set-kubeconfig.sh

# Option 3: Manually export (temporary)
export KUBECONFIG=~/.kube/microk8s-config
```

**Note**: The setup script automatically adds `export KUBECONFIG=~/.kube/microk8s-config` to your `~/.bashrc`, so new shells will have it set automatically.

### 3. Wait for Deployment

The initial deployment takes 5-10 minutes. Monitor progress:

```bash
# Watch all pods
watch kubectl get pods -A

# Check Flux
flux get all -A
```

### 3. Access Services

Once all pods are running:

#### ServiceExample Application

```bash
# Access via NodePort
curl http://localhost:30080/api/person

# Or get the service URL
kubectl get svc serviceexample
```

#### Grafana Dashboard

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open browser to http://localhost:3000
# Username: admin
# Password: prom-operator
```

#### Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090
```

#### Longhorn UI

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
# Open http://localhost:8080
```

## Repository Structure

```
ServiceExampleGitOps/
├── terraform/              # Terraform configuration
│   ├── main.tf            # Main Terraform config
│   ├── variables.tf       # Terraform variables
│   ├── outputs.tf         # Terraform outputs
│   ├── setup.sh          # Setup script
│   └── destroy.sh        # Cleanup script
│
├── flux/                  # FluxCD GitOps configuration
│   ├── sources/          # Git and Helm sources
│   │   ├── gitrepository.yaml
│   │   └── helmrepositories.yaml
│   │
│   ├── infrastructure/   # Infrastructure components
│   │   ├── longhorn/    # Storage
│   │   └── monitoring/  # Prometheus, Grafana, Loki
│   │
│   └── apps/            # Applications
│       └── serviceexample/  # ServiceExample app
│
└── README.md
```

## GitOps Workflow

### Automatic Updates

FluxCD is configured to:

1. **Monitor Git Repository** (every minute)
   - Checks <https://github.com/AjtonyP/ServiceExampleGitOps.git>
   - Automatically applies changes

2. **Monitor Helm Repository** (every 5 minutes)
   - Checks <https://ajtonyp.github.io/ServiceExampleHelm>
   - Detects new chart versions matching `>=0.2.0`
   - Automatically applies new Helm chart versions
   - Updates are triggered only when a new Helm chart is published

## Cleanup

To completely remove the cluster and all data:

```bash
cd terraform
./destroy.sh
```

This will:

- Remove all Kubernetes resources
- Uninstall MicroK8s
- Delete kubeconfig
- Clean Terraform state``

## Monitoring & Observability

### Pre-configured Dashboards

Grafana includes:

- **ServiceExample Dashboard**: Application metrics
- **Kubernetes Dashboards**: Cluster health
- **Loki Logs**: Centralized logging

### Accessing Metrics

ServiceExample exposes metrics at:

- `http://serviceexample:9080/metrics` (Prometheus format)
- `http://serviceexample:9080/health` (Health checks)

### View Logs in Grafana

1. Open Grafana (see Access Services above)
2. Go to Explore
3. Select "Loki" datasource
4. Query: `{namespace="default", app="serviceexample"}`
