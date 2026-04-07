# Private DNS Zone Module
# -----------------------
# Creates a private DNS zone and links it to a virtual network.
# Private DNS zones enable name resolution for private endpoints,
# ensuring resources are reachable by FQDN over the private network
# without exposing traffic to the public internet.

resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the DNS zone to the VNet so that resources within the VNet
# can resolve records in this private zone automatically.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}
