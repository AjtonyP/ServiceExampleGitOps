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
./setup.sh
```

This script will:

1. Install MicroK8s
2. Enable required addons (DNS, storage, MetalLB)
3. Install FluxCD
4. Bootstrap GitOps configuration
5. Deploy all infrastructure and applications

### 2. Wait for Deployment

The initial deployment takes 5-10 minutes. Monitor progress:

```bash
export KUBECONFIG=~/.kube/microk8s-config

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

1. **Monitor Helm Repository** (every 5 minutes)
   - Checks <https://ajtonyp.github.io/ServiceExampleHelm>
   - Detects new chart versions matching `>=0.2.0`
   - Automatically applies new Helm chart versions
   - Updates are triggered only when a new Helm chart is published

**Note**: Docker image updates are managed through the Helm chart version. When you publish a new Helm chart with an updated image tag, FluxCD will deploy it automatically.

### Manual Sync

Force FluxCD to reconcile:

```bash
# Sync specific HelmRelease
flux reconcile helmrelease serviceexample -n flux-system

# Sync all
flux reconcile source git serviceexample-gitops
flux reconcile kustomization -n flux-system --all
```

## Resource Configuration

All components are configured with minimal resources for local development:

| Component | CPU Request | Memory Request | Storage |
|-----------|-------------|----------------|---------|
| ServiceExample | 50m | 128Mi | - |
| MongoDB | 100m | 128Mi | 1Gi |
| Redis | 50m | 64Mi | 500Mi |
| NATS | 25m | 32Mi | - |
| Prometheus | 100m | 512Mi | 5Gi |
| Grafana | 50m | 128Mi | 1Gi |
| Loki | 100m | 256Mi | 5Gi |
| Longhorn | 50m | 128Mi | - |

**Total**: ~625m CPU, ~1.5Gi RAM

## Troubleshooting

### Check Flux Status

```bash
# Overall status
flux get all -A

# Check sources
flux get sources all -A

# Check HelmReleases
flux get helmreleases -A

# View logs
kubectl logs -n flux-system -l app=helm-controller -f
```

### Check Application Logs

```bash
# ServiceExample app
kubectl logs -f deployment/serviceexample

# MongoDB
kubectl logs -f statefulset/mongodb-0

# Prometheus
kubectl logs -n monitoring -f statefulset/prometheus-kube-prometheus-stack-prometheus
```

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
