# -------------------------
# Tags 
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
# Azure Provider Authentication
# -------------------------
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "client_id" {
  type        = string
  default     = ""
  description = "Azure client ID for service principal"
}

variable "client_secret" {
  type        = string
  default     = ""
  description = "Azure client secret for service principal"
}

variable "tenant_id" {
  type        = string
  default     = ""
  description = "Azure tenant ID"
}

# -------------------------
# Private DNS for Function App Private Endpoint
# -------------------------
check "private_dns_inputs" {
  assert {
    condition = (
      var.enforce_private_dns_zone_resolution == false
      || var.private_dns_zone_id != ""
      || var.private_dns_zone_rg_name != ""
    )
    error_message = "When enforce_private_dns_zone_resolution is true, provide private_dns_zone_id or private_dns_zone_rg_name."
  }
}
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
# Regions (dynamic N)
# -------------------------
variable "regions" {
  description = "Dynamic N regions. Keys are Azure region codes (e.g., westus2, westus)."
  type = map(object({
    # Function + plan
    function_app_name   = string
    resource_group_name = string
    service_plan_name   = string

    service_plan_sku_name = optional(string, "EP2")
    worker_count          = optional(number, 2)
    enable_zone_balancing = optional(bool, true)
    # Additional Service Plan parameters
    service_plan_os_type                         = optional(string, "Linux")
    service_plan_maximum_elastic_worker_count    = optional(number, null)
    service_plan_per_site_scaling_enabled        = optional(bool, false)
    service_plan_premium_plan_auto_scale_enabled = optional(bool, false)
    service_plan_app_service_environment_id      = optional(string, null)
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
    # ✅ Linux runtime stack selector
    # Allowed values: "java", "dotnet", "node", "python", "powershell"
    runtime_stack = optional(string, "python") # Default to Python as it's Linux-native

    # Java
    java_version = optional(string, "17")

    # .NET (examples: "6.0", "7.0", "8.0")
    dotnet_version = optional(string, "8.0")

    # Node (examples: "~18", "~20")
    node_version = optional(string, "~20")

    # Python (examples: "~3.9", "~3.10", "~3.11")
    python_version = optional(string, "~3.11")

    # PowerShell (examples: "7.2", "7.4")
    powershell_core_version     = optional(string, "7.4")
    functions_extension_version = optional(string, "~4")
    https_only                  = optional(bool, true)
    always_on                   = optional(bool, true)
    ftps_state                  = optional(string, "Disabled")
    vnet_route_all_enabled      = optional(bool, true)

    # Additional Function App optional parameters
    builtin_logging_enabled                  = optional(bool, false)
    client_certificate_enabled               = optional(bool, false)
    client_certificate_mode                  = optional(string, "Required")
    client_certificate_exclusion_paths       = optional(list(string), [])
    daily_memory_time_quota                  = optional(number, null)
    enabled                                  = optional(bool, true)
    ftp_publish_basic_authentication_enabled = optional(bool, true)
    key_vault_reference_identity_id          = optional(string, null)
    public_network_access_enabled            = optional(bool, false)
    storage_uses_managed_identity            = optional(bool, true)
    virtual_network_subnet_id                = optional(string, null)
    zip_deploy_file                          = optional(string, null)

    # Region-specific settings/tags
    app_settings = optional(map(string), {})
    tags         = optional(map(string), {})
  }))
}
