data "azurerm_client_config" "current" {}

# If a full private DNS zone ID isn't supplied, look it up by name + RG
data "azurerm_private_dns_zone" "websites" {
  count               = var.private_dns_zone_id == "" && var.private_dns_zone_rg_name != "" ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg_name
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
