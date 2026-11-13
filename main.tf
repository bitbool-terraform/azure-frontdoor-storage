resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.storage_resource_group
  location                        = var.location
  account_kind                    = var.storage_kind
  account_tier                    = var.storage_tier
  account_replication_type        = var.storage_replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = var.storage_public_network_access_enabled
  allow_nested_items_to_be_public = var.storage_allow_blob_public_access
  shared_access_key_enabled       = var.storage_shared_access_key_enabled
  tags                            = var.tags

  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_account_static_website" "this" {
  count              = var.origin_mode == "website" ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id
  index_document     = var.website_index_document
  error_404_document = var.website_error_document
}

resource "azurerm_storage_container" "this" {
  count                 = var.origin_mode == "blob" ? 1 : 0
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = var.blob_container_access
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.profile_name
  resource_group_name = var.frontdoor_resource_group
  sku_name            = var.profile_sku
  tags                = var.tags
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = var.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = true
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = var.origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = var.session_affinity_enabled

  load_balancing {
    sample_size                        = var.load_balancing_sample_size
    successful_samples_required        = var.load_balancing_successful_samples
    additional_latency_in_milliseconds = var.load_balancing_additional_latency_ms
  }

  dynamic "health_probe" {
    for_each = var.health_probe_enabled ? [1] : []
    content {
      path                = var.health_probe_path
      request_type        = "HEAD"
      protocol            = "Https"
      interval_in_seconds = var.health_probe_interval_seconds
    }
  }
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  name                          = var.origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                     = local.origin_host
  origin_host_header            = local.origin_host_header
  enabled                       = var.origin_enabled
  http_port                     = 80
  https_port                    = 443
  priority                      = var.origin_priority
  weight                        = var.origin_weight
  certificate_name_check_enabled = true

  dynamic "private_link" {
    for_each = var.private_link_enabled ? [1] : []
    content {
      request_message        = var.private_link_request_message
      target_type            = var.origin_mode == "website" ? "web" : "blob"
      location               = azurerm_storage_account.this.location
      private_link_target_id = azurerm_storage_account.this.id
    }
  }

  # Static Website endpoint must exist before a new Front Door origin can reference it.
  depends_on = [azurerm_storage_account_static_website.this]
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each                 = var.custom_domains
  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name                = each.value.host_name
  dns_zone_id              = each.value.dns_zone_id
  tls {
    certificate_type      = each.value.certificate_type
    cdn_frontdoor_secret_id = each.value.secret_id
  }
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_rule_set" "this" {
  for_each                 = var.rule_set_names
  name                     = each.value
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = var.route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]
  cdn_frontdoor_custom_domain_ids = [for d in azurerm_cdn_frontdoor_custom_domain.this : d.id]
  cdn_frontdoor_rule_set_ids      = [for s in azurerm_cdn_frontdoor_rule_set.this : s.id]
  enabled                       = true
  origin_path                   = local.origin_path
  patterns_to_match             = var.route_patterns
  supported_protocols           = var.route_supported_protocols
  forwarding_protocol           = var.route_forwarding_protocol
  https_redirect_enabled        = var.route_https_redirect_enabled
  link_to_default_domain        = var.route_link_to_default_domain

  dynamic "cache" {
    for_each = var.route_cache_enabled ? [1] : []
    content {
      query_string_caching_behavior = var.route_query_string_caching_behavior
      compression_enabled           = var.route_compression_enabled
      content_types_to_compress = [
        "application/javascript", "text/javascript", "text/css", "application/json", "image/svg+xml"
      ]
    }
  }
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  for_each                       = var.custom_domains
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this[each.key].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this.id]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  count               = local.waf_enabled ? 1 : 0
  name                = var.waf_policy_name
  resource_group_name = var.frontdoor_resource_group
  sku_name            = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags
  # Match all existing managed_rule/custom_rule blocks here before applying.
  lifecycle { prevent_destroy = true }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count                    = local.waf_enabled ? 1 : 0
  name                     = var.waf_security_policy_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[0].id
      association {
        dynamic "domain" {
          for_each = concat(
            var.waf_attach_default_domain ? [azurerm_cdn_frontdoor_endpoint.this.id] : [],
            [for d in azurerm_cdn_frontdoor_custom_domain.this : d.id]
          )
          content { cdn_frontdoor_domain_id = domain.value }
        }
        patterns_to_match = ["/*"]
      }
    }
  }
  lifecycle { prevent_destroy = true }
}

resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  count                      = var.log_analytics_workspace_id == null ? 0 : 1
  name                       = coalesce(var.diagnostic_setting_name, "${var.profile_name}-diagnostics")
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}


