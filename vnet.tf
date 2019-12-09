resource "azurerm_virtual_network" "spoke" {
  name                = format("spoke%03d",var.name)
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.spoke.name}"
  address_space       = ["${var.vnet_cidr}"]

  subnet {
    name           = "default"
    address_prefix = cidrsubnet( var.vnet_cidr,8,1)
  }
}