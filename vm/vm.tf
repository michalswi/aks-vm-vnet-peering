
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
    # private_ip_address_allocation = "Static"
    # private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_virtual_machine" "main" {
    name                  = "${var.vm_name}-vm"
    location              = azurerm_resource_group.vm.location
    resource_group_name   = azurerm_resource_group.vm.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size               = "Standard_B1ls"

    # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    # Uncomment this line to delete the data disks automatically when deleting the VM
    delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "osdisk1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "azuretest"
        admin_username = "zbyszek"
        admin_password = "Password1?"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "dev"
    }
}

data "azurerm_public_ip" "datapip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_virtual_machine.main.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.datapip.ip_address
}