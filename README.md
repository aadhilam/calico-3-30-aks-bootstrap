# AKS Calico Bootstrap

This repo spins up an **Azure Kubernetes Service** cluster that uses the **BYO‑CNI** option (`--network-plugin none`)
and then installs **Project Calico** with Helm.  
It is completely unattended – one command provisions the infrastructure, installs Calico, and applies any YAML
manifests found in `manifests/`.

## Quick start

Get a list of supported Kuberentes versions - az aks get-versions --location eastus -o table
Replace variable "k8s_version" with a supported version. 


```bash
# clone & enter
git clone <your‑fork‑url>.git
cd aks-calico-bootstrap

# provision everything
make up
```

### Tear down

```bash
make down
```

## Requirements

| Tool | Version |
|------|---------|
| Azure CLI | 2.59+ |
| Terraform | 1.7+ |
| Helm | 3.13+ |

Make sure you've logged in to Azure and selected the right subscription:

```bash
az login
az account set --subscription <SUB_ID>
# Export it so the provider sees it
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

```

## How it works

1. Terraform creates a resource group and an AKS cluster with `network_plugin = "none"`.
2. The Helm provider installs the `tigera-operator` chart.
3. Any YAML files in `manifests/` are applied via the Kubernetes provider.

Adjust values in **`terraform/variables.tf`** or override them at apply time:

```bash
make up TF_VAR_project=mydemo TF_VAR_location=westeurope
```
