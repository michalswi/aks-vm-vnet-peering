resource "azurerm_resource_group" "kluster" {
  name     = "${var.name}-private-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-vnet"
  location            = azurerm_resource_group.kluster.location
  resource_group_name = azurerm_resource_group.kluster.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.kluster.name
  address_prefixes     = ["10.20.2.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_kubernetes_cluster" "kluster" {
  name                = "${var.name}-k8s"
  location            = azurerm_resource_group.kluster.location
  resource_group_name = azurerm_resource_group.kluster.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  private_cluster_enabled = true

  default_node_pool {
    name           = "agentpool"
    node_count     = var.agent_count
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  node_resource_group = "${var.name}-nrg"

  service_principal {
      client_id     = var.client_id
      client_secret = var.client_secret
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
