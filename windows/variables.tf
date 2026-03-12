# -------------------------
# DNS inputs (same pattern)
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
# Tags (same as your KV module)
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
# Key Vault RBAC (existing vault referenced per region)
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
# Regions (dynamic N regions) - Windows Function App
# -------------------------
variable "regions" {
  description = "Regions to deploy into; keys are Azure region codes."
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

    # Key Vault (name+RG)
    key_vault_name    = string
    key_vault_rg_name = string

    # Runtime common settings
    functions_extension_version = optional(string, "~4")
    https_only                  = optional(bool, true)
    always_on                   = optional(bool, true)

    # ✅ Windows runtime stack selector
    # Allowed values: "java", "dotnet", "node", "powershell"
    runtime_stack = optional(string, "java")

    # Java
    java_version = optional(string, "17")

    # .NET (examples: "v6.0", "v7.0", "v8.0")
    dotnet_version = optional(string, "v8.0")

    # Node (examples: "~18", "~20")
    node_version = optional(string, "~20")

    # PowerShell (examples: "7.2")
    powershell_core_version = optional(string, "7.2")

    # App settings & tags
    app_settings = optional(map(string), {})
    tags         = optional(map(string), {})
  }))
}