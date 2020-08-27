terraform {
  required_providers {
    azurerm = {  
            source  = "hashicorp/azurerm"
            version = "~> 2.12"
    }
    newrelic = {
  source  = "newrelic/newrelic"
      version = "~> 2.1.1"
    }
  }
}

resource "azurerm_resource_group" "Terra1" {
    name     = "Terra1"
    location = "koreacentral"

    
}

resource "azurerm_virtual_network" "T-Vnet" {
    name = "T-Vnet"
    address_space = ["10.3.0.0/16"]
    location ="koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name
}
resource "azurerm_subnet" "T-Sub" {
    name = "T-Sub"
    resource_group_name = azurerm_resource_group.Terra1.name
    virtual_network_name = azurerm_virtual_network.T-Vnet.name
    address_prefixes = ["10.3.0.0/24"]
}
resource "azurerm_public_ip" "T-Pubip" {
    name = "T-Pubip"
    location ="koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name
    allocation_method = "Dynamic"
}
resource "azurerm_network_security_group" "H-Nsg" {
    name = "H-Nsg"
    location = "koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name
    security_rule {
        name ="SSH"
        priority =1001
        direction = "Inbound"
        access ="Allow"
        protocol ="TCP"
        source_port_range ="*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
        
    }


}