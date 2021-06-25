
resource "azurerm_resource_group" "vm" {
    name     = var.rg_name
    location = var.location
}

resource "azurerm_virtual_network" "vnet" {
    name                = "${var.vm_name}-vnet"
    location            = azurerm_resource_group.vm.location
    resource_group_name = azurerm_resource_group.vm.name
    address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
    name                 = "${var.vm_name}-subnet"
    resource_group_name  = azurerm_resource_group.vm.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.30.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                    = "${var.vm_name}-pip"
  location                = azurerm_resource_group.vm.location
  resource_group_name     = azurerm_resource_group.vm.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "vmipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
    name                  = "${var.vm_name}-vm"
    location              = azurerm_resource_group.vm.location
    resource_group_name   = azurerm_resource_group.vm.name
    size               = "Standard_B1ls"

    admin_username = "zbych"
    admin_ssh_key {
      username   = "zbych"
      public_key = file("test.pub")
    }

    computer_name  = "demo"

    network_interface_ids = [
      azurerm_network_interface.nic.id
    ]

    source_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

    os_disk {
      name                  = "${var.vm_name}disk1"
      caching               = "ReadWrite"
      storage_account_type  = "Standard_LRS"
    }

    tags = {
        environment = "dev"
    }
}

output "ssh_username" {
  value = azurerm_linux_virtual_machine.main.admin_username
}

data "azurerm_public_ip" "datapip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_linux_virtual_machine.main.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.datapip.ip_address
}