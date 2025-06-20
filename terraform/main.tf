provider "azurerm" {
  features {}
}

# ---------------- Resource Group ----------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project}"
  location = var.location
}

# ---------------- AKS Cluster -------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = var.k8s_version
  dns_prefix          = "dns-${var.project}"

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_DS3_v2"
    node_count = 3
  }

  network_profile {
    network_plugin = "none"
    pod_cidr       = "10.244.0.0/16" # Calico default
  }

  identity {
    type = "SystemAssigned"
  }
}
# ─── Save kubeconfig to disk ────────────────────────────────────────────────
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "${path.module}/../kubeconfig"
  file_permission = "0600"
}

# ---------------- Providers wired to cluster ----
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

resource "time_sleep" "wait_for_cluster_ready" {
  depends_on = [azurerm_kubernetes_cluster.aks, local_file.kubeconfig]
  create_duration = "120s"  # Increase to 2 minutes
}

# Add this resource to properly set up kubeconfig before Helm operations
resource "null_resource" "setup_kubeconfig" {
  depends_on = [local_file.kubeconfig, time_sleep.wait_for_cluster_ready]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/../kubeconfig
      kubectl cluster-info 
      kubectl get nodes
    EOT
  }
}

# ---------------- Calico install ----------------
resource "null_resource" "install_calico" {
  depends_on = [time_sleep.wait_for_cluster_ready]

  triggers = {
    kubeconfig_changed = md5(local_file.kubeconfig.content)
  }

  # Install Calico
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/../kubeconfig
      kubectl cluster-info || (echo "Cluster not accessible" && exit 1)
      helm repo add tigera-operator https://docs.tigera.io/calico/charts || true
      helm repo update
      helm upgrade --install tigera-operator tigera-operator/tigera-operator \
        --version v3.30.0 \
        --namespace tigera-operator \
        --create-namespace \
        --values ${path.module}/calico-values.yaml
    EOT
  }
}

# ─── Apply all YAML in ./manifests once the cluster & Calico are ready ─────
resource "null_resource" "extras" {
  triggers = {
    manifest_hash = sha1(join("", sort(fileset("${path.module}/../manifests", "**"))))
  }

  provisioner "local-exec" {
    command = <<-EOT
      for i in $(seq 1 6); do 
        kubectl apply -f ${path.module}/../manifests && break || \
        (echo 'retrying in 20 s…' && sleep 20)
      done
    EOT

    environment = {
      KUBECONFIG = "${path.module}/../kubeconfig"
    }
  }

  # Change dependency from helm_release to null_resource
  depends_on = [
    null_resource.install_calico,
    local_file.kubeconfig
  ]
}