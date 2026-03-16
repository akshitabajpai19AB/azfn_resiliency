output "function_apps" {
  value = {
    for region, _cfg in var.regions :
    region => {
      id       = azurerm_linux_function_app.func[region].id
      name     = azurerm_linux_function_app.func[region].name
      hostname = azurerm_linux_function_app.func[region].default_hostname
      region   = region
    }
  }
}
