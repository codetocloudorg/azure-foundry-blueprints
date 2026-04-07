# Private Endpoint Module
# -----------------------
# Creates a private endpoint for a target Azure resource, routing traffic
# over the VNet instead of the public internet. Integrates with private
# DNS zones to enable FQDN-based resolution of the private IP.

resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  # The service connection links this endpoint to a specific subresource
  # on the target resource (e.g. "vault" for Key Vault, "blob" for Storage).
  private_service_connection {
    name                           = "${var.name}-connection"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  # Register the private endpoint IP in the supplied private DNS zone(s)
  # so that the resource FQDN resolves to the private IP within the VNet.
  private_dns_zone_group {
    name                 = "${var.name}-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}
