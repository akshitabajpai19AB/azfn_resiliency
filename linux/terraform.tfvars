#######################################
# Global tags (same as KV pattern)
#######################################
appcode     = "ALBS"
appname     = "functions"
costcenter  = "12345"
environment = "dev"
portfolio   = "retail"
drtier      = "tier1"

#######################################
# Private DNS for Function App PE
#######################################
private_dns_zone_id        = ""
private_dns_zone_name      = "privatelink.azurewebsites.net"
private_dns_zone_rg_name   = "rg-dns-dev"
private_dns_zone_group     = "websites-privatelink"

#######################################
# Front Door (single global instance)
#######################################
# frontdoor_resource_group_name = "rg-frontdoor-dev"
# frontdoor_profile_name        = "afd-albs-dev"
# frontdoor_endpoint_name       = "afd-albs-dev-ept"

# frontdoor_origin_group_name   = "og-functions"
# frontdoor_route_name          = "route-functions"

# frontdoor_health_probe_path                = "/health"
# frontdoor_health_probe_interval_in_seconds = 30
# frontdoor_health_probe_protocol            = "Https"
# frontdoor_health_probe_request_type        = "HEAD"

# frontdoor_patterns_to_match      = ["/*"]
# frontdoor_supported_protocols    = ["Https"]
# frontdoor_https_redirect_enabled = true
# frontdoor_forwarding_protocol    = "HttpsOnly"

#######################################
# Storage RBAC
#######################################
storage_rbac_roles = [
  "Storage Blob Data Contributor",
  "Storage Queue Data Contributor",
  "Storage Table Data Contributor"
]

#######################################
# Key Vault RBAC
#######################################
enable_kv_rbac = true
kv_role_definition_name = "Key Vault Secrets User"

#######################################
# Regions (N regions – add/remove freely)
#######################################
regions = {
  westus2 = {
    function_app_name   = "albs-func-westus2-dev"
    resource_group_name = "new2"
    service_plan_name   = "asp-albs-westus2-dev"

    service_plan_sku_name = "EP2"
    worker_count          = 2
    enable_zone_balancing = true

    storage_account_name                = "stalbsfuncdev"
    storage_account_resource_group_name = "rg-albs-storage-dev"

    application_insights_name                = "appi-albs-westus2-dev"
    application_insights_resource_group_name = "rg-albs-monitoring-dev"

    vnet_name                = "vnet-albs-westus2"
    vnet_resource_group_name = "rg-albs-network-dev"

    inbound_private_endpoint_subnet_name = "snet-private-endpoints"
    outbound_integration_subnet_name     = "snet-appservice-integration"

    private_endpoint_name            = "pe-albs-func-westus2-dev"
    private_endpoint_connection_name = "psc-albs-func-westus2-dev"

    key_vault_name    = "kv-albs-westus2-dev"
    key_vault_rg_name = "rg-albs-kv-dev"

    java_version                = "17"
    functions_extension_version = "~4"
    https_only                  = true
    always_on                   = true

    app_settings = {
      REGION = "westus2"
      SAMPLE_SETTING = "demo"
      # Example KV reference:
      # DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=https://kv-albs-westus2-dev.vault.azure.net/secrets/DbPassword)"
    }

    tags = {
      region = "westus2"
    }
  }

  westus = {
    function_app_name   = "albs-func-westus-dev"
    resource_group_name = "new"
    service_plan_name   = "asp-albs-westus-dev"

    service_plan_sku_name = "EP2"
    worker_count          = 2
    enable_zone_balancing = true

    storage_account_name                = "stalbsfuncdev"
    storage_account_resource_group_name = "rg-albs-storage-dev"

    application_insights_name                = "appi-albs-westus-dev"
    application_insights_resource_group_name = "rg-albs-monitoring-dev"

    vnet_name                = "vnet-albs-westus"
    vnet_resource_group_name = "rg-albs-network-dev"

    inbound_private_endpoint_subnet_name = "snet-private-endpoints"
    outbound_integration_subnet_name     = "snet-appservice-integration"

    private_endpoint_name            = "pe-albs-func-westus-dev"
    private_endpoint_connection_name = "psc-albs-func-westus-dev"

    key_vault_name    = "kv-albs-westus-dev"
    key_vault_rg_name = "rg-albs-kv-dev"

    app_settings = {
      REGION = "westus"
    }

    tags = {
      region = "westus"
    }
  }
}
