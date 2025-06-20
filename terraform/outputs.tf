output "kubeconfig_raw" {
  description = "Raw kubeconfig for the new AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
