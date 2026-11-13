output "frontdoor_hostname" { value = azurerm_cdn_frontdoor_endpoint.this.host_name }
output "frontdoor_profile_id" { value = azurerm_cdn_frontdoor_profile.this.id }
output "frontdoor_endpoint_id" { value = azurerm_cdn_frontdoor_endpoint.this.id }
output "storage_account_id" { value = azurerm_storage_account.this.id }
output "storage_origin_hostname" { value = local.origin_host }