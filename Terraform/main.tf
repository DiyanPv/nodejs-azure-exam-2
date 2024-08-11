# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "3.115.0"  # You can specify the version you want
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

# resource "azurerm_app_service_plan" "app_service_plan" {
#   name                = "${var.app_service_name}-plan"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku {
#     tier = "Basic"
#     size = "B1"
#   }
# }

# resource "azurerm_app_service" "app_service" {
#   name                = var.app_service_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
#   site_config {
#     dotnet_framework_version = "v4.0"
#   }
# }

# resource "azurerm_sql_server" "sql_server" {
#   name                         = var.sql_server_name
#   resource_group_name          = azurerm_resource_group.rg.name
#   location                     = azurerm_resource_group.rg.location
#   version                      = "12.0"
#   administrator_login          = var.sql_admin_username
#   administrator_login_password = var.sql_admin_password
# }

# resource "azurerm_sql_database" "sql_database" {
#   name                = var.sql_database_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   server_name         = azurerm_sql_server.sql_server.name
#   sku_name            = "Basic"
# }

# resource "azurerm_app_service_slot" "deployment_slot" {
#   name                = "staging"
#   app_service_name    = azurerm_app_service.app_service.name
#   resource_group_name = azurerm_resource_group.rg.name
#   app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
# }

# output "app_service_default_site_hostname" {
#   value = azurerm_app_service.app_service.default_site_hostname
# }

# output "sql_server_name" {
#   value = azurerm_sql_server.sql_server.name
# }

# output "sql_database_name" {
#   value = azurerm_sql_database.sql_database.name
# }



terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.115.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_service_plan" "asp" {
  name                = "softunibazarsp"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "bazarapp" {
  name                = "SoftUniBazarApp"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = var.sqlserver_name
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

}

resource "azurerm_mssql_database" "database" {
  name           = "example-db"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_app_service_source_control" "sql_taskboard" {
  app_id                 = azurerm_linux_web_app.bazarapp.id
  repo_url               = var.repo_url
  branch                 = "main"
  use_manual_integration = true
}

resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
