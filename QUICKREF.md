# ServiceExample Local Development - Quick Reference

## Initial Setup

```bash
cd ~/work/ServiceExampleGitOps/terraform
./setup.sh
export KUBECONFIG=~/.kube/microk8s-config
```

## Essential Commands

### Cluster Management

```bash
# Check MicroK8s status
microk8s status

# View all pods
kubectl get pods -A

# Watch pods in real-time
watch kubectl get pods -A
```

### Flux Operations

```bash
# Check Flux status
flux get all -A

# Force sync everything
flux reconcile source git serviceexample-gitops -n flux-system
flux reconcile helmrelease serviceexample -n flux-system

# View Flux logs
kubectl logs -n flux-system -l app=helm-controller -f
```

### ServiceExample App

```bash
# View logs
kubectl logs -f deployment/serviceexample

# Restart
kubectl rollout restart deployment/serviceexample

# Test endpoints
curl http://localhost:30080/health
curl http://localhost:30080/metrics
curl http://localhost:30080/api/person
```

### Monitoring Access

#### Grafana

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000
# Login: admin / prom-operator
```

#### Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090
```

#### Longhorn

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
# Open http://localhost:8080
```

### Helper Script

```bash
# Quick status
~/ServiceExampleGitOps/scripts/helper.sh status

# Show all services
~/ServiceExampleGitOps/scripts/helper.sh services

# View logs
~/ServiceExampleGitOps/scripts/helper.sh logs serviceexample

# Port forward
~/ServiceExampleGitOps/scripts/helper.sh port-forward grafana

```

## Troubleshooting

### Pods Not Starting

```bash
# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod <pod-name>

# Check PVCs
kubectl get pvc -A
```

### Flux Not Syncing

```bash
# Check HelmRelease status
kubectl describe helmrelease -n flux-system serviceexample

# Check sources
flux get sources all -A

# Reconcile manually
flux reconcile helmrelease serviceexample -n flux-system
```

### Resource Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Reduce replicas temporarily
kubectl scale deployment serviceexample --replicas=0
```

## Update Workflow

### Local Changes

```bash
# Edit files in flux/
vim flux/apps/serviceexample/release.yaml

# Commit and push
git add .
git commit -m "Update configuration"
git push

# Flux auto-syncs within 1 minute
# Or force sync:
flux reconcile source git serviceexample-gitops -n flux-system
```

### New ServiceExample Version

FluxCD automatically detects and deploys new Helm chart versions from:

- Helm Repository: <https://ajtonyp.github.io/ServiceExampleHelm>

Check status:

```bash
flux get helmreleases -A
```

Check status:

```bash
flux get images all -A
```

## Cleanup

```bash
cd ~/work/ServiceExampleGitOps/terraform
./destroy.sh
```

## Resource Limits

Current configuration (minimal for local dev):

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| ServiceExample | 50m-200m | 128Mi-256Mi | - |
| MongoDB | 100m-250m | 128Mi-256Mi | 1Gi |
| Redis | 50m-100m | 64Mi-128Mi | 500Mi |
| NATS | 25m-50m | 32Mi-64Mi | - |
| Prometheus | 100m-500m | 512Mi-1Gi | 5Gi |
| Grafana | 50m-200m | 128Mi-256Mi | 1Gi |
| Loki | 100m-500m | 256Mi-512Mi | 5Gi |

**Total**: ~625m CPU, ~1.5Gi RAM, ~13.5Gi Storage
