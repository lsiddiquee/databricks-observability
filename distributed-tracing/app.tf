# Create the Linux App Service Plan
resource "azurerm_service_plan" "this" {
  name                = var.webapp_service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "B1"
}

#  Create application deployment zip from local
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/${var.app_subdirectory}"
  output_path = "${path.module}/app.zip"
  excludes = setunion(
    fileset("${path.module}/${var.app_subdirectory}", "*.env*"),
    fileset("${path.module}/${var.app_subdirectory}", "__pycache__/**")
  )
}

# Create a random ID to ensure unique app name
resource "random_id" "app_name_suffix" {
  byte_length = 8
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "this" {
  name                  = lower("${var.webapp_name}-${random_id.app_name_suffix.hex}")
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  service_plan_id       = azurerm_service_plan.this.id
  https_only            = true
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
    "OTEL_SERVICE_NAME" = "Distributed Tracing Sample Service"
    "OTEL_PYTHON_EXCLUDED_URLS" = "azuredatabricks.net/api/2.0/jobs/run-now"
    "OTEL_BLRP_SCHEDULE_DELAY" = "500"
    "OTEL_BSP_SCHEDULE_DELAY" = "500"
  }
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITES_ENABLE_APP_SERVICE_STORAGE"],
      app_settings["SCM_DO_BUILD_DURING_DEPLOYMENT"],
    ]
  }
}

#  Deploy in Azure App Service
resource "null_resource" "deploy_app" {
  provisioner "local-exec" {
    command = "az webapp deploy --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_linux_web_app.this.name} --src-path ${data.archive_file.app_zip.output_path} --timeout 1000000"
  }
  depends_on = [
    azurerm_linux_web_app.this
  ]
}

#  Setup custom startup command to allow to set worker count
resource "null_resource" "app_increase_worker_count" {
  provisioner "local-exec" {
    command = "az webapp config set --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_linux_web_app.this.name} --startup-file start.sh"
  }
  depends_on = [
    null_resource.deploy_app
  ]
}