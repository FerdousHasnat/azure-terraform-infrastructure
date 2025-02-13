
# Define the Terraform provider for Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the provider to use Azure
provider "azurerm" {
  features {}
}

# Create an Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "Terraform-RG"
  location = "East US"
}

# Create an Azure Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "Terraform-VNet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create a Subnet for Virtual Machines
resource "azurerm_subnet" "vm_subnet" {
  name                 = "VM-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Subnet for Database
resource "azurerm_subnet" "db_subnet" {
  name                 = "DB-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
# Create NSG for VM-Subnet (Allows SSH & HTTP)
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "VM-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow SSH (Port 22) in VM-Subnet
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Allow HTTP (Port 80) in VM-Subnet
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow-HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Attach NSG to VM-Subnet
resource "azurerm_subnet_network_security_group_association" "vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Create NSG for DB-Subnet (Blocks all external access)
resource "azurerm_network_security_group" "db_nsg" {
  name                = "DB-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Attach NSG to DB-Subnet
resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Create a Public IP for the VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "VM-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create a Network Interface for the VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "VM-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "VM-IPConfig"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "Terraform-VM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s" # Free-tier eligible VM size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Uses local SSH key
  }

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
# Create an Azure Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "Terraform-LogAnalytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018" # Pay-as-you-go pricing for logs
  retention_in_days   = 30          # Retains logs for 30 days
}

# Enable Monitoring for VM
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name                       = "VM-Monitoring"
  target_resource_id         = azurerm_linux_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = "terraform-sql-server-${random_string.suffix.result}" # Unique name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "adminuser"
  administrator_login_password = "YourStrongPassword123!"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_mssql_database" "sql_database" {
  name      = "terraform-sqldb"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic" # Free-tier database
}

resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "terraform-sql-private-endpoint"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "sql-private-connection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}


resource "azurerm_storage_container" "terraform_container" {
  name                  = "terraform-state"
  storage_account_name  = "tfstate22002255" 
  container_access_type = "private"
}


terraform {
  backend "azurerm" {
    resource_group_name  = "Terraform-RG"
    storage_account_name = "tfstate22002255" 
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}


