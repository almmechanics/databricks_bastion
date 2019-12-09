resource "azurerm_resource_group" "bastion" {
  name     = format("rg_bastion_%03d",var.name)
  location = "${var.location}"
}

resource "azurerm_subnet" "bastion" {
    name     = "AzureBastionSubnet"
    resource_group_name  = "${azurerm_resource_group.spoke.name}"
    virtual_network_name = "${azurerm_virtual_network.spoke.name}"
    address_prefix = cidrsubnet( var.vnet_cidr,11,16)
}

resource "azurerm_public_ip" "bastion" {
  name                = format("pipbastion%03d",var.name)
  location            = "${azurerm_resource_group.bastion.location}"
  resource_group_name = "${azurerm_resource_group.bastion.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = format("bastion%03d",var.name)
  location            = "${azurerm_resource_group.bastion.location}"
  resource_group_name = "${azurerm_resource_group.bastion.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.bastion.id}"
    public_ip_address_id = "${azurerm_public_ip.bastion.id}"
  }
}