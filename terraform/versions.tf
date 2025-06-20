terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm    = { source = "hashicorp/azurerm",    version = ">= 3.115.0" }
    helm       = { source = "hashicorp/helm",       version = ">= 2.13.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30.0" }
  }
}
