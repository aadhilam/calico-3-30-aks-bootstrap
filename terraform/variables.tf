variable "project" {
  description = "Project suffix used in resource names"
  type        = string
  default     = "calico-demo"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "k8s_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.31.8"
}
