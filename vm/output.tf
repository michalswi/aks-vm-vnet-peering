output "ssh_username" {
  value = azurerm_linux_virtual_machine.main.admin_username
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

data "azurerm_public_ip" "datapip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_linux_virtual_machine.main.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.datapip.ip_address
}