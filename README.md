# azure-frontdoor-storage

# Copy to terraform.tfvars and replace all placeholders with the values ALREADY in Azure.
subscription_id           = "00000000-0000-0000-0000-000000000000"
frontdoor_resource_group  = "existing-frontdoor-rg"
storage_resource_group    = "existing-storage-rg"
location                  = "westeurope"

profile_name              = "existing-afd-profile"
profile_sku               = "Standard_AzureFrontDoor" # Or Premium_AzureFrontDoor
endpoint_name             = "existing-afd-endpoint"
origin_group_name         = "existing-origin-group"
origin_name               = "existing-origin"
route_name                = "existing-route"
storage_account_name      = "existingstorageaccount"
storage_replication_type  = "LRS" # Match existing storage account SKU

origin_mode               = "website" # Or "blob" when origin points to blob endpoint
# blob_container_name     = "cdn"
# blob_container_access   = "blob" # For public blob origin with Standard SKU
# storage_allow_blob_public_access = true
# private_link_enabled    = true   # Only if already configured on Premium SKU

# custom_domains = {
#   existingDomain = { host_name = "cdn.example.com" }
# }
# waf_policy_name            = "existingwafpolicy"
# waf_security_policy_name   = "existingSecurityPolicy"
# rule_set_names             = ["existingRuleSet"]
# log_analytics_workspace_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/..."
# diagnostic_setting_name    = "existing-diagnostic-name"

tags = {} # Replace with the provider's actual tags before applying.