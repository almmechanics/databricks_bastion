resource "azurerm_resource_group" "spoke" {
  name     = format("rg_spoke_%03d",var.name)
  location = "${var.location}"
}