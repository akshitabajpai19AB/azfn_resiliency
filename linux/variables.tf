# -------------------------
# Tags (same set as your Key Vault module)
# -------------------------
variable "appcode" {
  type = string
}

variable "appname" {
  type = string
}

variable "costcenter" {
  type = string
}

variable "environment" {
  type = string
}

variable "portfolio" {
  type = string
}

variable "drtier" {
  type = string
}

# -------------------------
# Private DNS for Function App Private Endpoint
# Keep DNS selection "as-is"
# -------------------------
variable "private_dns_zone_id" {
  type        = string
  default     = ""
  description = "Full resource ID of privatelink.azurewebsites.net. If empty, it will be looked up by name + RG."
}

variable "private_dns_zone_name" {
  type    = string
  default = "privatelink.azurewebsites.net"
}

variable "private_dns_zone_rg_name" {
  type    = string
  default = ""
}

variable "private_dns_zone_group" {
  type    = string
  default = "websites-privatelink"
}

variable "enforce_private_dns_zone_resolution" {
  type    = bool
  default = true

  validation {
    condition     = var.enforce_private_dns_zone_resolution == false || var.private_dns_zone_id != "" || var.private_dns_zone_rg_name != ""
    error_message = "Set private_dns_zone_id or private_dns_zone_rg_name (or disable enforce_private_dns_zone_resolution)."
  }
}

# -------------------------
# Storage RBAC roles for Function MI
# -------------------------
variable "storage_rbac_roles" {
  type = list(string)
  default = [
    "Storage Blob Data Contributor",
    "Storage Queue Data Contributor",
    "Storage Table Data Contributor"
  ]
}

# -------------------------
# Key Vault RBAC for Key Vault references
# KV exists and is referenced by name+RG per region
# -------------------------
variable "enable_kv_rbac" {
  type    = bool
  default = true
}

variable "kv_role_definition_name" {
  type    = string
  default = "Key Vault Secrets User"
}

# -------------------------
# Front Door (single global instance)
# -------------------------
# variable "frontdoor_resource_group_name" {
#   type = string
# }

# variable "frontdoor_profile_name" {
#   type = string
# }

# variable "frontdoor_endpoint_name" {
#   type = string
# }

# variable "frontdoor_origin_group_name" {
#   type    = string
#   default = "og-functions"
# }

# variable "frontdoor_route_name" {
#   type    = string
#   default = "route-functions"
# }

# variable "frontdoor_health_probe_path" {
#   type    = string
#   default = "/health"
# }

# variable "frontdoor_health_probe_interval_in_seconds" {
#   type    = number
#   default = 30
# }

# variable "frontdoor_health_probe_protocol" {
#   type    = string
#   default = "Https"
# }

# variable "frontdoor_health_probe_request_type" {
#   type    = string
#   default = "HEAD"
# }

# variable "frontdoor_patterns_to_match" {
#   type    = list(string)
#   default = ["/*"]
# }

# variable "frontdoor_supported_protocols" {
#   type    = list(string)
#   default = ["Https"]
# }

# variable "frontdoor_https_redirect_enabled" {
#   type    = bool
#   default = true
# }

# variable "frontdoor_forwarding_protocol" {
#   type    = string
#   default = "HttpsOnly"
# }

# -------------------------
# Regions (dynamic N)
# -------------------------
variable "regions" {
  description = "Dynamic N regions. Keys are Azure region codes (e.g., westus2, westus)."
  type = map(object({
    # Function + plan
    function_app_name     = string
    resource_group_name   = string
    service_plan_name     = string

    service_plan_sku_name  = optional(string, "EP2")
    worker_count           = optional(number, 2)
    enable_zone_balancing  = optional(bool, true)

    # Existing shared services
    storage_account_name                = string
    storage_account_resource_group_name = string

    application_insights_name                = string
    application_insights_resource_group_name = string

    # Network
    vnet_name                = string
    vnet_resource_group_name = string

    inbound_private_endpoint_subnet_name = string
    outbound_integration_subnet_name     = string

    private_endpoint_name            = string
    private_endpoint_connection_name = string

    # Key Vault reference (name+RG always)
    key_vault_name    = string
    key_vault_rg_name = string

    # Runtime
    java_version                = optional(string, "17")
    functions_extension_version = optional(string, "~4")
    https_only                  = optional(bool, true)
    always_on                   = optional(bool, true)

    # Region-specific settings/tags
    app_settings = optional(map(string), {})
    tags         = optional(map(string), {})
  }))
}
