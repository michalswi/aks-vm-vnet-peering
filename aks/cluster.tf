
resource "azurerm_resource_group" "kluster" {
    name     = var.rg_name
    location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.kluster.location
  resource_group_name = azurerm_resource_group.kluster.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.kluster.name
  address_prefixes     = ["10.20.2.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_kubernetes_cluster" "kluster" {
    name                = var.cluster_name
    location            = azurerm_resource_group.kluster.location
    resource_group_name = azurerm_resource_group.kluster.name
    dns_prefix          = var.dns_prefix
    kubernetes_version  = var.kubernetes_version

    private_cluster_enabled = true

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_B2s"
        vnet_subnet_id  = azurerm_subnet.subnet.id
    }

    node_resource_group = "${var.cluster_name}-k8s"

    identity {
        type = "SystemAssigned"
    }

    network_profile {
        network_plugin = var.network_plugin
    }

    role_based_access_control {
        enabled = true
    }

    tags = {
        Environment = "dev"
    }
}

output "host" {
    value = azurerm_kubernetes_cluster.kluster.kube_config.0.host
}
