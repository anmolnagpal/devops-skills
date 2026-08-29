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

data "azurerm_subscription" "current" {}

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

# Log Analytics workspace with an audit-compliant retention (400 days).
resource "azurerm_log_analytics_workspace" "audit" {
  name                = "acme-prod-audit"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 400
  tags                = local.tags
}

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

# Cluster diagnostic setting: exports the control-plane audit categories to the
# Log Analytics workspace, so AKS actually collects an audit trail.
resource "azurerm_monitor_diagnostic_setting" "aks_audit" {
  name                       = "acme-prod-aks-audit"
  target_resource_id         = azurerm_kubernetes_cluster.platform.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.audit.id

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-apiserver"
  }
}

# Subscription-scoped diagnostic setting: sends the Azure Activity Log to the
# same workspace, so subscription-level actions are retained and queryable
# alongside the cluster audit logs.
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "acme-prod-activity-log"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.audit.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Policy"
  }
}
