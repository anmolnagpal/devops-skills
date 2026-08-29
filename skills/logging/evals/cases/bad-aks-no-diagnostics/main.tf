terraform {
  required_version = "~> 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "acme-tfstate-rg"
    storage_account_name = "acmetfstate"
    container_name       = "tfstate"
    key                  = "env/prod/aks.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  tags = {
    Name        = "acme-prod-aks"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# AKS cluster with no diagnostic setting shipping kube-audit categories, and no
# subscription-scoped Activity Log diagnostic setting. No audit trail is collected.
resource "azurerm_kubernetes_cluster" "platform" {
  name                = "acme-prod-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "acme-prod-aks"

  default_node_pool {
    name       = "system"
    node_count = 3
    vm_size    = "Standard_D4s_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
