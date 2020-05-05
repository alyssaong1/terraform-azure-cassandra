provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}


resource "azurerm_resource_group" "cassandra" {
  name     = "${var.naming_prefix}rg"
  location = var.location
}

resource "azurerm_network_security_group" "cassandra" {
  name                = "${var.naming_prefix}nsg"
  location            = azurerm_resource_group.cassandra.location
  resource_group_name = azurerm_resource_group.cassandra.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "cass-internal"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "cass-client"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9042"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "cass-jmx"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7199"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_virtual_network" "cassandra" {
  name                = "${var.naming_prefix}vnet"
  location            = azurerm_resource_group.cassandra.location
  resource_group_name = azurerm_resource_group.cassandra.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "cassandra" {
  count                = length(var.subnet_prefix)
  name                 = "subnet-${count.index}"
  resource_group_name  = "${azurerm_resource_group.cassandra.name}"
  virtual_network_name = "${azurerm_virtual_network.cassandra.name}"
  address_prefix       = "${element(var.subnet_prefix, count.index)}"
}

resource "azurerm_network_interface" "cassandra" {
  count               = var.vm_count
  name                = "nic${count.index}"
  location            = azurerm_resource_group.cassandra.location
  resource_group_name = azurerm_resource_group.cassandra.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cassandra[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "cassandra" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.cassandra[count.index].id
  network_security_group_id = azurerm_network_security_group.cassandra.id
}

resource "azurerm_linux_virtual_machine" "cassandra" {
  count               = var.vm_count
  name                = "devvm-${count.index}"
  resource_group_name = azurerm_resource_group.cassandra.name
  location            = azurerm_resource_group.cassandra.location
  size                = var.vm_sku
  disable_password_authentication = "false"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.cassandra[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}