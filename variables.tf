variable "subscription_id" { type = string }
variable "frontdoor_resource_group" { type = string }
variable "storage_resource_group" { type = string }
variable "location" { type = string } # Existing Storage region, e.g. "westeurope"

variable "profile_name" { type = string }
variable "profile_sku" {
  type    = string
  default = "Standard_AzureFrontDoor" # Or Premium_AzureFrontDoor
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.profile_sku)
    error_message = "Only Front Door Standard and Premium are supported."
  }
}
variable "endpoint_name" { type = string }
variable "origin_group_name" { type = string }
variable "origin_name" { type = string }
variable "route_name" { type = string }

variable "storage_account_name" { type = string }
variable "storage_replication_type" {
  type = string
  default = "LRS"
}
variable "storage_tier" {
  type = string
  default = "Standard"
}
variable "storage_kind" {
  type = string
  default = "StorageV2"
}
variable "storage_public_network_access_enabled" {
  type = bool
  default = true
}
variable "storage_allow_blob_public_access" {
  type = bool
  default = false
}
variable "storage_shared_access_key_enabled" {
  type = bool
  default = true
}
variable "storage_use_azuread" {
  type = bool
  default = false
}
variable "tags" {
  type = map(string)
  default = {}
}


# "website": Storage static website ($web); "blob": a regular blob container.
# Match the provider's existing origin; do not change modes during adoption.
variable "origin_mode" {
  type    = string
  default = "website"
  validation {
    condition     = contains(["website", "blob"], var.origin_mode)
    error_message = "origin_mode must be website or blob."
  }
}
variable "blob_container_name" {
  type = string
  default = "cdn"
}
variable "blob_container_access" {
  type = string
  default = "private" # Use blob for public Blob-origin reads.
}
variable "website_index_document" {
  type = string
  default = "index.html"
}
variable "website_error_document" {
  type = string
  default = null
}
variable "origin_host_override" {
  type = string
  default = null
}
variable "origin_host_header_override" {
  type = string
  default = null
}
variable "origin_path_override" {
  type = string
  default = null
}

variable "private_link_enabled" {
  type = bool
  default = false # Requires Premium + manual approval.
}
variable "private_link_request_message" {
  type = string
  default = "Front Door access to Storage origin"
}

variable "health_probe_enabled" {
  type = bool
  default = false # For JS-only origin, / may return 404.
}
variable "health_probe_path" {
  type = string
  default = "/"
}
variable "health_probe_interval_seconds" {
  type = number
  default = 120
}
variable "session_affinity_enabled" {
  type = bool
  default = false
}
variable "origin_enabled" {
  type = bool
  default = true
}
variable "origin_priority" {
  type = number
  default = 1
}
variable "origin_weight" {
  type = number
  default = 1000
}
variable "load_balancing_sample_size" {
  type = number
  default = 4
}
variable "load_balancing_successful_samples" {
  type = number
  default = 3
}
variable "load_balancing_additional_latency_ms" {
  type = number
  default = 50
}

variable "route_patterns" {
  type = list(string)
  default = ["/*"]
}
variable "route_supported_protocols" {
  type = list(string)
  default = ["Http", "Https"]
}
variable "route_forwarding_protocol" {
  type = string
  default = "HttpsOnly"
}
variable "route_https_redirect_enabled" {
  type = bool
  default = true
}
variable "route_link_to_default_domain" {
  type = bool
  default = true
}
variable "route_cache_enabled" {
  type = bool
  default = true
}
variable "route_compression_enabled" {
  type = bool
  default = true
}
variable "route_query_string_caching_behavior" {
  type = string
  default = "IgnoreQueryString"
}

# Map keys are existing Azure *resource names*, not hostnames.
# Example: { cdnexamplecom = { host_name = "cdn.example.com" } }
variable "custom_domains" {
  type = map(object({
    host_name        = string
    dns_zone_id      = optional(string)
    certificate_type = optional(string, "ManagedCertificate")
    secret_id        = optional(string) # Existing Front Door secret ID, for CustomerCertificate
  }))
  default = {}
}

# Optional existing WAF policy (include only if it exists or you want to create it).
# Add the provider's existing custom/managed rules in the firewall policy before applying.
variable "waf_policy_name" {
  type = string
  default = null
}
variable "waf_security_policy_name" {
  type = string
  default = null
}
variable "waf_mode" {
  type = string
  default = "Prevention"
}
variable "waf_attach_default_domain" {
  type = bool
  default = true
}

# Optional existing rule set names: this template associates them, but rule actions
# must be declared/imported separately if they already exist.
variable "rule_set_names" {
  type = set(string)
  default = []
}

# Existing LAW ID, if diagnostics are managed by this state; null means disabled.
variable "diagnostic_setting_name" {
  type = string
  default = null
}
variable "log_analytics_workspace_id" {
  type = string
  default = null
}