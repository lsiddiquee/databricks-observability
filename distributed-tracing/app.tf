# Create the Linux App Service Plan
resource "azurerm_service_plan" "this" {
  name                = var.webapp_service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "B1"
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/${var.app_subdirectory}"
  output_path = "${path.module}/app.zip"
  excludes = [ "${path.module}/${var.app_subdirectory}/.env", "${path.module}/${var.app_subdirectory}/.env.tftpl", "${path.module}/${var.app_subdirectory}/__pycache__" ]
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "this" {
  name                  = var.webapp_name
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  service_plan_id       = azurerm_service_plan.this.id
  https_only            = true
  webdeploy_publish_basic_authentication_enabled = false
  zip_deploy_file       = data.archive_file.app_zip.output_path
  site_config { 
    minimum_tls_version = "1.2"
    application_stack {
      python_version    = "3.11"
    }
  }
  app_settings          = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.this.connection_string
    "DATABRICKS_HOST" = "https://${azurerm_databricks_workspace.this.workspace_url}"
    "DATABRICKS_TOKEN" = databricks_token.this.token_value
    "DATABRICKS_JOB_ID" = databricks_job.this.id
  }
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITES_ENABLE_APP_SERVICE_STORAGE"],
      app_settings["SCM_DO_BUILD_DURING_DEPLOYMENT"],
    ]
  }
}

#  Create application deployment zip from local and deploy in Azure App Service
resource "null_resource" "zip" {
  provisioner "local-exec" {
    command = <<EOT
      az webapp deploy --resource-group ${azurerm_resource_group.this.name} --name${azurerm_linux_web_app.this.name} --src-path ${data.archive_file.app_zip.output_path}
    EOT
  }

  depends_on = [
    azurerm_linux_web_app.this
  ]
}