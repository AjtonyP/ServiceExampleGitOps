variable "microk8s_channel" {
  description = "MicroK8s snap channel"
  type        = string
  default     = "1.31/stable"
}

variable "microk8s_addons" {
  description = "List of MicroK8s addons to enable"
  type        = list(string)
  default = [
    "dns",
    "hostpath-storage",
  ]
}

variable "kubeconfig_dir" {
  description = "Directory to store kubeconfig"
  type        = string
  default     = "~/.kube"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/microk8s-config"
}

variable "flux_version" {
  description = "Flux version to install"
  type        = string
  default     = "latest"
}

variable "gitops_repo_path" {
  description = "Path to local GitOps repository"
  type        = string
  default     = "../"
}
