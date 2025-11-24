output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = var.kubeconfig_path
}

output "cluster_status" {
  description = "Instructions for accessing the cluster"
  value       = <<-EOT
    MicroK8s cluster is ready!
    
    Set kubeconfig:
      export KUBECONFIG=${var.kubeconfig_path}
    
    Check cluster status:
      microk8s status
      
    Check Flux status:
      flux get all -A
      
    Access Grafana:
      kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
      Default: admin/prom-operator
      
    Access ServiceExample:
      kubectl get svc -n default serviceexample
  EOT
}
