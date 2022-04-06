terraform {
  required_version = ">= 0.12"


  required_providers {
    azurerm = {
    source = "hashicorp/azurerm"
    version = ">= 2.26"
    }
  }
  
}
provider "azurerm" {

  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

  }
}
resource "azurerm_resource_group" "infracloudjay" {
  name     = "terraformaulainfrajay"
  location = "australiaeast"
}

resource "azurerm_virtual_network" "vm-infrajay" {
  name                = "vm-infrajay"
  location            = azurerm_resource_group.infracloudjay.location
  resource_group_name = azurerm_resource_group.infracloudjay.name
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    environment = "Production"
    aluno = "jaysllan"
    curso = "engenhariasoftware"
  }
}

resource "azurerm_subnet" "subnetinfrajay" {
  name                 = "sub-aulajay"
  resource_group_name  = azurerm_resource_group.infracloudjay.name
  virtual_network_name = azurerm_virtual_network.vm-infrajay.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ipinfrajay" {
  name                = "ip-pulicjay"
  resource_group_name = azurerm_resource_group.infracloudjay.name
  location            = azurerm_resource_group.infracloudjay.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "securityinfrajay" {
  name                = "securityjay"
  location            = azurerm_resource_group.infracloudjay.location
  resource_group_name = azurerm_resource_group.infracloudjay.name

  security_rule {
    name                       = "SSH"
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
    name                       = "web"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "interfaceinfrajay" {
  name                = "interface-jay"
  location            = azurerm_resource_group.infracloudjay.location
  resource_group_name = azurerm_resource_group.infracloudjay.name

  ip_configuration {
    name                          = "ip-infra-jay"
    subnet_id                     = azurerm_subnet.subnetinfrajay.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ipinfrajay.id
  }
}

resource "azurerm_network_interface_security_group_association" "netinfrajay" {
  network_interface_id      = azurerm_network_interface.interfaceinfrajay.id
  network_security_group_id = azurerm_network_security_group.securityinfrajay.id
}

resource "azurerm_virtual_machine" "maquina-infra-jay" {
  name                  = "maquinavirtualjay"
  location              = azurerm_resource_group.infracloudjay.location
  resource_group_name   = azurerm_resource_group.infracloudjay.name
  network_interface_ids = [azurerm_network_interface.interfaceinfrajay.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

data "azurerm_public_ip" "ip-publicojay" {

  name =  azurerm_public_ip.ipinfrajay.name
  resource_group_name = azurerm_resource_group.infracloudjay.name
}

resource "null_resource" "install-apache" {
  
  connection {
    type = "ssh"
    host = data.azurerm_public_ip.ip-publicojay.ip_address
    user = "testadmin"
    password = "Password1234!"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
    ]
  }
  depends_on = [
    azurerm_virtual_machine.maquina-infra-jay
  ]
}