provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}


resource "azurerm_resource_group" "cassandra" {
  count    = length(var.location)
  name     = "${var.naming_prefix}-${count.index}-rg"
  location = element(var.location, count.index)
}

resource "azurerm_network_security_group" "cassandra" {
  count               = length(var.location)
  name                = "msg-${var.naming_prefix}-${count.index}"
  location            = element(var.location, count.index)
  resource_group_name = element(azurerm_resource_group.cassandra.*.name, count.index)

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
  count               = length(var.location)
  name                = "vnet-${var.naming_prefix}-${count.index}"
  location            = element(var.location, count.index)
  resource_group_name = element(azurerm_resource_group.cassandra.*.name, count.index)
  address_space       = [element(var.address_space, count.index)]

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "cassandra" {
  count                = length(var.subnet_prefix)
  name                 = "subnet-${count.index}"
  resource_group_name  = element(azurerm_resource_group.cassandra.*.name, count.index)
  virtual_network_name = element(azurerm_virtual_network.cassandra.*.name, count.index)
  address_prefix       = element(var.subnet_prefix, count.index)
}

# enable global peering between the two virtual network
resource "azurerm_virtual_network_peering" "cassandra" {
  count                        = length(var.location)
  name                         = "vnetpeer-${element(azurerm_virtual_network.cassandra.*.name, 1 - count.index)}"
  resource_group_name          = element(azurerm_resource_group.cassandra.*.name, count.index)
  virtual_network_name         = element(azurerm_virtual_network.cassandra.*.name, count.index)
  remote_virtual_network_id    = element(azurerm_virtual_network.cassandra.*.id, 1 - count.index)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
}

resource "azurerm_public_ip" "cassandra" {
  count               = length(var.location)
  name                = "${var.naming_prefix}-pip-${count.index}"
  location            = element(var.location, count.index)
  resource_group_name = element(azurerm_resource_group.cassandra.*.name,count.index)
  allocation_method   = "Dynamic"
  idle_timeout_in_minutes=30
}

resource "azurerm_network_interface" "cassandra" {
  count               = length(var.location)
  name                = "nic-${count.index}"
  location            = element(var.location, count.index)
  resource_group_name = element(azurerm_resource_group.cassandra.*.name, count.index)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = element(azurerm_subnet.cassandra.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.cassandra.*.id, count.index)
  }
}

resource "azurerm_network_interface_security_group_association" "cassandra" {
  count                     = length(var.location)
  network_interface_id      = element(azurerm_network_interface.cassandra.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.cassandra.*.id, count.index)
}

resource "azurerm_linux_virtual_machine" "cassandra" {
  count               = length(var.location)
  name                = "${var.naming_prefix}-dev-${count.index}"
  resource_group_name = element(azurerm_resource_group.cassandra.*.name, count.index)
  location            = element(var.location, count.index)
  size                = var.vm_sku
  disable_password_authentication = "false"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    element(azurerm_network_interface.cassandra.*.id, count.index),
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