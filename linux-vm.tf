variable "vmindex" {
    type = string
    default = 1
}

variable "vmname" {
    type = string
    default = 1
}


resource "azurerm_resource_group" "iaas" {
  name     = format("rg_iaas_%03d",var.name)
  location = "${var.location}"
}


resource "azurerm_subnet" "iaas" {
    name     = format("iaas%03s",var.name)
    resource_group_name  = "${azurerm_resource_group.spoke.name}"
    virtual_network_name = "${azurerm_virtual_network.spoke.name}"
    address_prefix = cidrsubnet( var.vnet_cidr,8,3)
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.iaas.name}"
  }

  byte_length = 8
}

resource "random_password" "password" {
  length = 24
  min_upper = 5
  min_special =5
  min_numeric =5
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.iaas.name}"
  location = "West Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_network_interface" "main" {
  name                = format("nic-vm%03d%03d", var.name, var.vmname)
  location            = "${azurerm_resource_group.iaas.location}"
  resource_group_name = "${azurerm_resource_group.iaas.name}"

  ip_configuration {
    name                          = format("ip-configuration%03d%03d",  var.name, var.vmname) 
    subnet_id                     = "${azurerm_subnet.iaas.id}"
    private_ip_address_allocation = "Dynamic"
  }

}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name     = format("vm%03d%03d", var.name, var.vmname)

  location            = "${azurerm_resource_group.iaas.location}"
  resource_group_name   = "${azurerm_resource_group.iaas.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_B1ls"

  storage_os_disk {
    name              = format("dsk-vm%03d%03d-os", var.name, var.vmname)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }
  os_profile {
    computer_name  = format("bastion%03d",var.name)
    admin_username = "bastionadmin"
    admin_password = "${random_password.password.result}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

}

output "password" {
  value = ["${random_password.password.result}"]
}
