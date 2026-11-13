locals {
  origin_host = coalesce(
    var.origin_host_override,
    var.origin_mode == "website" ? azurerm_storage_account.this.primary_web_host : azurerm_storage_account.this.primary_blob_host
  )
  origin_host_header = coalesce(var.origin_host_header_override, local.origin_host)
  origin_path        = var.origin_path_override != null ? var.origin_path_override : (var.origin_mode == "blob" ? "/${var.blob_container_name}" : null)
  waf_enabled        = var.waf_policy_name != null && var.waf_security_policy_name != null
}