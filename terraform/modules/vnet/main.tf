# Virtual Network Module
# ----------------------
# Creates an Azure Virtual Network with configurable subnets.
# Subnets are created inline to avoid lifecycle issues with separate
# azurerm_subnet resources when using dynamic blocks.

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags
}

# Each subnet is created as a discrete resource so that downstream modules
# can reference individual subnet IDs without depending on the entire VNet.
resource "azurerm_subnet" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = each.value.address_prefixes
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
}
