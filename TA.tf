provider "azurerm" {

version = "~>2.0"
    features {}
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

resource "azurerm_network_interface" "T-inter" {
    name ="T-inter"
    location ="koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name

    ip_configuration {
        name ="T-Nic"
        subnet_id =azurerm_subnet.T-Sub.id
        private_ip_address_allocation ="Dynamic"
        public_ip_address_id = azurerm_public_ip.T-Pubip.id
     }
}
    resource "azurerm_network_interface_security_group_association" "T-ex" {
        network_interface_id = azurerm_network_interface.T-inter.id
        network_security_group_id = azurerm_network_security_group.H-Nsg.id
    }

resource "random_id" "T-Rid" {
    keepers = {
        resource_group = azurerm_resource_group.Terra1.name
    }
    byte_length = 8
}
   
resource "azurerm_storage_account" "T-account" {
    name = "diag${random_id.T-Rid.hex}"
    resource_group_name = azurerm_resource_group.Terra1.name
    location ="koreacentral"
    account_replication_type = "LRS"
    account_tier = "Standard"
}

resource "tls_private_key" "T-ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}

output "tls_private_key" { value = "tls_private_key.T-ssh.private_key_pem" }

resource "azurerm_linux_virtual_machine" "T-VM" {
    name = "T-VM"
    location = "koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name
    network_interface_ids = [azurerm_network_interface.T-inter.id]
    size = "Standard_DS1_V2"
    os_disk {
        name = "T-disk"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"

    }
    source_image_reference {
        publisher = "Canonical"
        offer ="UbuntuServer"
        sku = "16.04.0-LTS"
        version = "latest"
    }
    computer_name = "T-VM"
    admin_username = "Cloud365123"
    admin_password = "Cloud365123!"

    admin_ssh_key {
        username = "Cloud365123"
        public_key = tls_private_key.T-ssh.public_key_openssh

    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.T-account.primary_blob_endpoint
    }

}
resource "azurerm_public_ip" "lbPip" {
    name ="lbPip"
    location = "koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name
    allocation_method = "Dynamic"
}

resource "azurerm_lb" "TerraLB" {
    name = "TerraLB"
    location = "koreacentral"
    resource_group_name = azurerm_resource_group.Terra1.name

    frontend_ip_configuration {
        name = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.lbPip.id
    }
}

resource "azurerm_lb_backend_address_pool" "backpool" {
    resource_group_name = azurerm_resource_group.Terra1.name
    loadbalancer_id = azurerm_lb.TerraLB.id
    name = "backpool"
}

resource "azurerm_lb_rule" "lb_rule" {
    resource_group_name = azurerm_resource_group.Terra1.name
    loadbalancer_id = azurerm_lb.TerraLB.id
    name = "lb_rule"
    protocol = "TCP"
    frontend_port = 80
    backend_port = 80
    frontend_ip_configuration_name = "PubIPAD"
}