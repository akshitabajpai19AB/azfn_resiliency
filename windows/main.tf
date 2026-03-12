data "azurerm_client_config" "current" {}

# Optional DNS data-source:
# If a full private DNS zone ID isn't supplied, look it up by name + RG
data "azurerm_private_dns_zone" "websites" {
  count               = var.private_dns_zone_id == "" && var.private_dns_zone_rg_name != "" ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg_name
}

locals {
  # Keep this condition as-is
  effective_private_dns_zone_id = var.private_dns_zone_id != "" ? var.private_dns_zone_id : (
    length(data.azurerm_private_dns_zone.websites) > 0 ? data.azurerm_private_dns_zone.websites[0].id : null
  )

  tags = {
    appcode     = var.appcode
    appname     = var.appname
    costcenter  = var.costcenter
    environment = var.environment
    portfolio   = var.portfolio
    drtier      = var.drtier
  }

  functions = {
    for region, cfg in var.regions :
    region => {
      region                           = region
      function_app_name                = cfg.function_app_name
      resource_group_name              = cfg.resource_group_name

      service_plan_name                = cfg.service_plan_name
      service_plan_sku_name            = lookup(cfg, "service_plan_sku_name", "EP2")
      worker_count                     = lookup(cfg, "worker_count", 2)
      enable_zone_balancing            = lookup(cfg, "enable_zone_balancing", true)

      storage_account_name             = cfg.storage_account_name
      storage_account_rg_name          = cfg.storage_account_resource_group_name

      appi_name                        = cfg.application_insights_name
      appi_rg_name                     = cfg.application_insights_resource_group_name

      vnet_name                        = cfg.vnet_name
      vnet_rg_name                     = cfg.vnet_resource_group_name
      inbound_pe_subnet_name           = cfg.inbound_private_endpoint_subnet_name
      outbound_integration_subnet_name = cfg.outbound_integration_subnet_name

      private_endpoint_name            = cfg.private_endpoint_name
      private_endpoint_connection_name = cfg.private_endpoint_connection_name

      key_vault_name                   = cfg.key_vault_name
      key_vault_rg_name                = cfg.key_vault_rg_name

      functions_extension_version      = lookup(cfg, "functions_extension_version", "~4")
      https_only                       = lookup(cfg, "https_only", true)
      always_on                        = lookup(cfg, "always_on", true)

      runtime_stack                    = lookup(cfg, "runtime_stack", "java")
      java_version                     = lookup(cfg, "java_version", "17")
      dotnet_version                   = lookup(cfg, "dotnet_version", "v8.0")
      node_version                     = lookup(cfg, "node_version", "~20")
      powershell_core_version          = lookup(cfg, "powershell_core_version", "7.2")

      app_settings                     = lookup(cfg, "app_settings", {})
      tags                             = lookup(cfg, "tags", {})
    }
  }
}

# -------------------------
# DATA: Existing shared services per region
# -------------------------
data "azurerm_storage_account" "sa" {
  for_each            = local.functions
  name                = each.value.storage_account_name
  resource_group_name = each.value.storage_account_rg_name
}

data "azurerm_application_insights" "appi" {
  for_each            = local.functions
  name                = each.value.appi_name
  resource_group_name = each.value.appi_rg_name
}

data "azurerm_key_vault" "kv" {
  for_each            = local.functions
  name                = each.value.key_vault_name
  resource_group_name = each.value.key_vault_rg_name
}

data "azurerm_subnet" "inbound_pe" {
  for_each             = local.functions
  name                 = each.value.inbound_pe_subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

data "azurerm_subnet" "outbound_integration" {
  for_each             = local.functions
  name                 = each.value.outbound_integration_subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

# -------------------------
# App Service Plan (EP2) - WINDOWS
# -------------------------
resource "azurerm_service_plan" "plan" {
  for_each            = local.functions
  name                = each.value.service_plan_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name

  os_type  = "Windows"
  sku_name = each.value.service_plan_sku_name

  worker_count           = each.value.worker_count
  zone_balancing_enabled = each.value.enable_zone_balancing

  tags = merge(each.value.tags, local.tags)
}

# -------------------------
# Windows Function App with storage_uses_managed_identity
# Windows Function App resource: azurerm_windows_function_app [3](https://registry.terraform.io/providers/hashicorp/azurerm/4.63.0/docs/resources/windows_function_app)
# -------------------------
resource "azurerm_windows_function_app" "func" {
  for_each            = local.functions
  name                = each.value.function_app_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name

  service_plan_id = azurerm_service_plan.plan[each.key].id

  storage_account_name          = data.azurerm_storage_account.sa[each.key].name
  storage_uses_managed_identity = true

  functions_extension_version   = each.value.functions_extension_version
  https_only                    = each.value.https_only
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on  = each.value.always_on
    ftps_state = "Disabled"

    # Choose ONE stack block based on runtime_stack
    dynamic "application_stack" {
      for_each = each.value.runtime_stack == "java" ? [1] : []
      content {
        java_version = each.value.java_version
      }
    }

    dynamic "application_stack" {
      for_each = each.value.runtime_stack == "dotnet" ? [1] : []
      content {
        dotnet_version = each.value.dotnet_version
      }
    }

    dynamic "application_stack" {
      for_each = each.value.runtime_stack == "node" ? [1] : []
      content {
        node_version = each.value.node_version
      }
    }

    dynamic "application_stack" {
      for_each = each.value.runtime_stack == "powershell" ? [1] : []
      content {
        powershell_core_version = each.value.powershell_core_version
      }
    }

    vnet_route_all_enabled = true
  }

  app_settings = merge(
    {
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = data.azurerm_application_insights.appi[each.key].connection_string
      "WEBSITE_RUN_FROM_PACKAGE"             = "1"
      "WEBSITE_ENABLE_SYNC_UPDATE_SITE"      = "true"
      "WEBSITE_VNET_ROUTE_ALL"               = "1"
    },
    each.value.app_settings
  )

  tags = merge(each.value.tags, local.tags)
}

# Outbound VNet integration (Swift connection) - supports Windows Function Apps too [1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection)
resource "azurerm_app_service_virtual_network_swift_connection" "swift" {
  for_each       = local.functions
  app_service_id = azurerm_windows_function_app.func[each.key].id
  subnet_id      = data.azurerm_subnet.outbound_integration[each.key].id
}

# Inbound Private Endpoint for Function App (Private Endpoint resource) [2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)
resource "azurerm_private_endpoint" "func_pe" {
  for_each            = local.functions
  name                = each.value.private_endpoint_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name
  subnet_id           = data.azurerm_subnet.inbound_pe[each.key].id

  private_service_connection {
    name                           = each.value.private_endpoint_connection_name
    private_connection_resource_id = azurerm_windows_function_app.func[each.key].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = local.effective_private_dns_zone_id == null ? [] : [local.effective_private_dns_zone_id]
    content {
      name                 = var.private_dns_zone_group
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }

  tags = merge(each.value.tags, local.tags)
}

# Storage RBAC assignments for Function MI
resource "azurerm_role_assignment" "storage_roles" {
  for_each = {
    for combo in flatten([
      for region, _cfg in local.functions : [
        for role in var.storage_rbac_roles : {
          key       = "${region}-${role}"
          region    = region
          role_name = role
        }
      ]
    ]) : combo.key => combo
  }

  scope                = data.azurerm_storage_account.sa[each.value.region].id
  role_definition_name = each.value.role_name
  principal_id         = azurerm_windows_function_app.func[each.value.region].identity[0].principal_id
}

# Key Vault RBAC assignment for Function MI (Key Vault references)
resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each = {
    for region, _cfg in local.functions :
    region => _cfg
    if var.enable_kv_rbac == true
  }

  scope                = data.azurerm_key_vault.kv[each.key].id
  role_definition_name = var.kv_role_definition_name
  principal_id         = azurerm_windows_function_app.func[each.key].identity[0].principal_id
}