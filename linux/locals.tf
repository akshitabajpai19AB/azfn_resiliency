locals {
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
      region              = region
      function_app_name   = cfg.function_app_name
      resource_group_name = cfg.resource_group_name

      service_plan_name     = cfg.service_plan_name
      service_plan_sku_name = lookup(cfg, "service_plan_sku_name", "EP2")
      worker_count          = lookup(cfg, "worker_count", 2)
      enable_zone_balancing = lookup(cfg, "enable_zone_balancing", true)

      # Additional Service Plan parameters
      service_plan_os_type                         = lookup(cfg, "service_plan_os_type", "Linux")
      service_plan_maximum_elastic_worker_count    = lookup(cfg, "service_plan_maximum_elastic_worker_count", null)
      service_plan_per_site_scaling_enabled        = lookup(cfg, "service_plan_per_site_scaling_enabled", false)
      service_plan_premium_plan_auto_scale_enabled = lookup(cfg, "service_plan_premium_plan_auto_scale_enabled", false)
      service_plan_app_service_environment_id      = lookup(cfg, "service_plan_app_service_environment_id", null)

      storage_account_name    = cfg.storage_account_name
      storage_account_rg_name = cfg.storage_account_resource_group_name

      appi_name    = cfg.application_insights_name
      appi_rg_name = cfg.application_insights_resource_group_name

      vnet_name                        = cfg.vnet_name
      vnet_rg_name                     = cfg.vnet_resource_group_name
      inbound_pe_subnet_name           = cfg.inbound_private_endpoint_subnet_name
      outbound_integration_subnet_name = cfg.outbound_integration_subnet_name

      private_endpoint_name            = cfg.private_endpoint_name
      private_endpoint_connection_name = cfg.private_endpoint_connection_name

      key_vault_name    = cfg.key_vault_name
      key_vault_rg_name = cfg.key_vault_rg_name

      runtime_stack           = lookup(cfg, "runtime_stack", "python")
      java_version            = lookup(cfg, "java_version", "17")
      dotnet_version          = lookup(cfg, "dotnet_version", "8.0")
      node_version            = lookup(cfg, "node_version", "~20")
      python_version          = lookup(cfg, "python_version", "~3.11")
      powershell_core_version = lookup(cfg, "powershell_core_version", "7.4")

      functions_extension_version = lookup(cfg, "functions_extension_version", "~4")
      https_only                  = lookup(cfg, "https_only", true)
      always_on                   = lookup(cfg, "always_on", true)
      ftps_state                  = lookup(cfg, "ftps_state", "Disabled")
      vnet_route_all_enabled      = lookup(cfg, "vnet_route_all_enabled", true)

      # Additional Function App optional parameters
      builtin_logging_enabled                  = lookup(cfg, "builtin_logging_enabled", false)
      client_certificate_enabled               = lookup(cfg, "client_certificate_enabled", false)
      client_certificate_mode                  = lookup(cfg, "client_certificate_mode", "Required")
      client_certificate_exclusion_paths       = lookup(cfg, "client_certificate_exclusion_paths", [])
      daily_memory_time_quota                  = lookup(cfg, "daily_memory_time_quota", null)
      enabled                                  = lookup(cfg, "enabled", true)
      ftp_publish_basic_authentication_enabled = lookup(cfg, "ftp_publish_basic_authentication_enabled", true)
      key_vault_reference_identity_id          = lookup(cfg, "key_vault_reference_identity_id", null)
      public_network_access_enabled            = lookup(cfg, "public_network_access_enabled", false)
      storage_uses_managed_identity            = lookup(cfg, "storage_uses_managed_identity", true)
      virtual_network_subnet_id                = lookup(cfg, "virtual_network_subnet_id", null)
      zip_deploy_file                          = lookup(cfg, "zip_deploy_file", null)

      app_settings = lookup(cfg, "app_settings", {})
      tags         = lookup(cfg, "tags", {})
    }
  }
}
