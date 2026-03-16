# -------------------------
# App Service Plan with zone balancing
# -------------------------
resource "azurerm_service_plan" "plan" {
  for_each            = local.functions
  name                = each.value.service_plan_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name

  os_type  = "Linux"
  sku_name = each.value.service_plan_sku_name

  worker_count           = each.value.worker_count
  zone_balancing_enabled = each.value.enable_zone_balancing

  # Optional parameters
  maximum_elastic_worker_count    = each.value.service_plan_maximum_elastic_worker_count
  per_site_scaling_enabled        = each.value.service_plan_per_site_scaling_enabled
  premium_plan_auto_scale_enabled = each.value.service_plan_premium_plan_auto_scale_enabled
  app_service_environment_id      = each.value.service_plan_app_service_environment_id

  tags = merge(each.value.tags, local.tags)
}

# -------------------------
# Linux Function App with storage_uses_managed_identity
# -------------------------
resource "azurerm_linux_function_app" "func" {
  for_each            = local.functions
  name                = each.value.function_app_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name

  service_plan_id = azurerm_service_plan.plan[each.key].id

  storage_account_name          = data.azurerm_storage_account.sa[each.key].name
  storage_uses_managed_identity = each.value.storage_uses_managed_identity

  builtin_logging_enabled                  = each.value.builtin_logging_enabled
  client_certificate_enabled               = each.value.client_certificate_enabled
  client_certificate_mode                  = each.value.client_certificate_mode
  client_certificate_exclusion_paths       = each.value.client_certificate_exclusion_paths
  daily_memory_time_quota                  = each.value.daily_memory_time_quota
  enabled                                  = each.value.enabled
  ftp_publish_basic_authentication_enabled = each.value.ftp_publish_basic_authentication_enabled
  functions_extension_version              = each.value.functions_extension_version
  https_only                               = each.value.https_only
  key_vault_reference_identity_id          = each.value.key_vault_reference_identity_id
  public_network_access_enabled            = each.value.public_network_access_enabled
  virtual_network_subnet_id                = each.value.virtual_network_subnet_id
  zip_deploy_file                          = each.value.zip_deploy_file

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on  = each.value.always_on
    ftps_state = each.value.ftps_state

    application_stack {
      dotnet_version          = each.value.runtime_stack == "dotnet" ? each.value.dotnet_version : null
      java_version            = each.value.runtime_stack == "java" ? each.value.java_version : null
      node_version            = each.value.runtime_stack == "node" ? each.value.node_version : null
      python_version          = each.value.runtime_stack == "python" ? each.value.python_version : null
      powershell_core_version = each.value.runtime_stack == "powershell" ? each.value.powershell_core_version : null
    }

    vnet_route_all_enabled = each.value.vnet_route_all_enabled
  }

  app_settings = merge(
    {
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = data.azurerm_application_insights.appi[each.key].connection_string
      "WEBSITE_RUN_FROM_PACKAGE"              = "1"
      "WEBSITE_ENABLE_SYNC_UPDATE_SITE"       = "true"
      "WEBSITE_VNET_ROUTE_ALL"                = "1"
    },
    each.value.app_settings
  )

  tags = merge(each.value.tags, local.tags)
}

# Outbound VNet integration (Swift connection)
resource "azurerm_app_service_virtual_network_swift_connection" "swift" {
  for_each       = local.functions
  app_service_id = azurerm_linux_function_app.func[each.key].id
  subnet_id      = data.azurerm_subnet.outbound_integration[each.key].id
}

# Inbound Private Endpoint for Function App
resource "azurerm_private_endpoint" "func_pe" {
  for_each            = local.functions
  name                = each.value.private_endpoint_name
  location            = each.value.region
  resource_group_name = each.value.resource_group_name
  subnet_id           = data.azurerm_subnet.inbound_pe[each.key].id

  private_service_connection {
    name                           = each.value.private_endpoint_connection_name
    private_connection_resource_id = azurerm_linux_function_app.func[each.key].id
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
  principal_id         = azurerm_linux_function_app.func[each.value.region].identity[0].principal_id
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
  principal_id         = azurerm_linux_function_app.func[each.key].identity[0].principal_id
}
