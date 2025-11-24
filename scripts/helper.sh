#!/bin/bash

# Helper script for common MicroK8s and Flux operations

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/microk8s-config}"
export KUBECONFIG

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

function print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

function print_success() {
    echo -e "${GREEN}$1${NC}"
}

function print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

function check_prerequisites() {
    if ! command -v microk8s &> /dev/null; then
        print_error "MicroK8s not installed. Run terraform/setup.sh first."
        exit 1
    fi
    
    if ! command -v flux &> /dev/null; then
        print_error "Flux CLI not installed."
        exit 1
    fi
}

function show_status() {
    print_header "Cluster Status"
    
    echo "MicroK8s Status:"
    microk8s status
    
    echo ""
    print_header "Flux Status"
    flux get all -A
    
    echo ""
    print_header "Pod Status"
    kubectl get pods -A
}

function show_services() {
    print_header "Service Endpoints"
    
    echo "ServiceExample:"
    echo "  NodePort: http://localhost:30080"
    echo ""
    
    echo "Grafana:"
    echo "  Run: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
    echo "  URL: http://localhost:3000"
    echo "  User: admin / prom-operator"
    echo ""
    
    echo "Prometheus:"
    echo "  Run: kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
    echo "  URL: http://localhost:9090"
    echo ""
    
    echo "Longhorn UI:"
    echo "  Run: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
    echo "  URL: http://localhost:8080"
    echo ""
}

function sync_flux() {
    print_header "Syncing Flux"
    
    print_info "Syncing GitRepository..."
    flux reconcile source git serviceexample-gitops -n flux-system
    
    print_info "Syncing HelmRepositories..."
    flux reconcile source helm serviceexample -n flux-system
    flux reconcile source helm longhorn -n flux-system
    flux reconcile source helm prometheus-community -n flux-system
    flux reconcile source helm grafana -n flux-system
    
    print_info "Syncing HelmReleases..."
    flux reconcile helmrelease longhorn -n flux-system
    flux reconcile helmrelease kube-prometheus-stack -n flux-system
    flux reconcile helmrelease loki -n flux-system
    flux reconcile helmrelease promtail -n flux-system
    flux reconcile helmrelease serviceexample -n flux-system
    
    print_success "Flux sync complete"
}

function show_logs() {
    local component="${1:-}"
    
    if [ -z "$component" ]; then
        echo "Usage: $0 logs <component>"
        echo ""
        echo "Available components:"
        echo "  flux           - Flux controllers"
        echo "  serviceexample - ServiceExample app"
        echo "  mongodb        - MongoDB"
        echo "  redis          - Redis"
        echo "  nats           - NATS"
        echo "  prometheus     - Prometheus"
        echo "  grafana        - Grafana"
        echo "  loki           - Loki"
        exit 1
    fi
    
    case "$component" in
        flux)
            kubectl logs -n flux-system -l app=source-controller -f
            ;;
        serviceexample)
            kubectl logs -f deployment/serviceexample
            ;;
        mongodb)
            kubectl logs -f statefulset/mongodb-0
            ;;
        redis)
            kubectl logs -f deployment/redis
            ;;
        nats)
            kubectl logs -f deployment/nats
            ;;
        prometheus)
            kubectl logs -n monitoring -f statefulset/prometheus-kube-prometheus-stack-prometheus
            ;;
        grafana)
            kubectl logs -n monitoring -f deployment/kube-prometheus-stack-grafana
            ;;
        loki)
            kubectl logs -n monitoring -f statefulset/loki
            ;;
        *)
            print_error "Unknown component: $component"
            exit 1
            ;;
    esac
}

function restart_app() {
    print_header "Restarting ServiceExample"
    kubectl rollout restart deployment/serviceexample
    kubectl rollout status deployment/serviceexample
    print_success "ServiceExample restarted"
}


function port_forward() {
    local service="${1:-}"
    
    case "$service" in
        grafana)
            print_info "Forwarding Grafana to http://localhost:3000"
            print_info "Username: admin, Password: prom-operator"
            kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
            ;;
        prometheus)
            print_info "Forwarding Prometheus to http://localhost:9090"
            kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
            ;;
        longhorn)
            print_info "Forwarding Longhorn UI to http://localhost:8080"
            kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
            ;;
        *)
            echo "Usage: $0 port-forward <service>"
            echo ""
            echo "Available services:"
            echo "  grafana    - Grafana dashboard"
            echo "  prometheus - Prometheus UI"
            echo "  longhorn   - Longhorn storage UI"
            exit 1
            ;;
    esac
}

function show_help() {
    cat << EOF
ServiceExample MicroK8s Helper Script

Usage: $0 <command> [options]

Commands:
  status           - Show cluster and Flux status
  services         - Show service endpoints
  sync             - Force Flux to reconcile all resources
  logs <component> - Show logs for a component
  restart          - Restart ServiceExample deployment
  test             - Test ServiceExample endpoints
  port-forward <service> - Port forward to a service
  help             - Show this help message

Examples:
  $0 status
  $0 logs serviceexample
  $0 sync
  $0 port-forward grafana
  $0 test

EOF
}

# Main
check_prerequisites

case "${1:-help}" in
    status)
        show_status
        ;;
    services)
        show_services
        ;;
    sync)
        sync_flux
        ;;
    logs)
        show_logs "$2"
        ;;
    restart)
        restart_app
        ;;
    port-forward|pf)
        port_forward "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
