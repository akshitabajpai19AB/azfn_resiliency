output "function_apps" {
  value = {
    for region, _cfg in var.regions :
    region => {
      id       = azurerm_windows_function_app.func[region].id
      name     = azurerm_windows_function_app.func[region].name
      hostname = azurerm_windows_function_app.func[region].default_hostname
      region   = region
    }
  }
}