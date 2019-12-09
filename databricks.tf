resource "azurerm_resource_group" "databricks" {
  name     = format("rg_databricks_%03d",var.name)
  location = "${var.location}"
}

resource "azurerm_subnet" "privatedatabricks" {
    name     = format("privatedatabricks%03s",var.name)
    resource_group_name  = "${azurerm_resource_group.spoke.name}"
    virtual_network_name = "${azurerm_virtual_network.spoke.name}"
    address_prefix = cidrsubnet( var.vnet_cidr,8,4)

    delegation {
        name = "databricks-del-private"

        service_delegation {
            name    = "Microsoft.Databricks/workspaces"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
        }
    }

}

resource "azurerm_subnet" "publicdatabricks" {
    name     = format("publicdatabricks%03s",var.name)
    resource_group_name  = "${azurerm_resource_group.spoke.name}"
    virtual_network_name = "${azurerm_virtual_network.spoke.name}"
    address_prefix = cidrsubnet( var.vnet_cidr,8,5)
    network_security_group_id = "${azurerm_network_security_group.databricks.id}"

    delegation {
        name = "databricks-del-public"

        service_delegation {
            name    = "Microsoft.Databricks/workspaces"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
        }
    }
}

resource "azurerm_network_security_group" "databricks" {
  name                = format("databricks-nsg-%03d",var.name)
  location            = "${azurerm_resource_group.databricks.location}"
  resource_group_name = "${azurerm_resource_group.databricks.name}"

}

resource "azurerm_subnet_network_security_group_association" "databricks" {
  subnet_id                 = "${azurerm_subnet.publicdatabricks.id}"
  network_security_group_id = "${azurerm_network_security_group.databricks.id}"
}


data "local_file" "armtemplate" {   
  filename = "./arm/databricks.json"
}

resource "azurerm_template_deployment" "databricks" {
  name                = format("databricks-%03d-deployment",var.name)
  resource_group_name = "${azurerm_resource_group.databricks.name}"
  template_body       = "${data.local_file.armtemplate.content}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName         =  format("workspace-%03d",var.name)
    vnetId              = "${azurerm_virtual_network.spoke.id}"
    privateSubnetId     = "${azurerm_subnet.privatedatabricks.address_prefix}"
    publicSubnetId     = "${azurerm_subnet.publicdatabricks.address_prefix}"
    pricingTier = "trial"
  }
}