output "resource_group_name" {
  value = azurerm_resource_group.this.name
  description = "The name of the resource group"
}

output "application_endpoint" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}/notebook"
}

output "databricks_workspace_url" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}"
  description = "The URL of the Databricks workspace"
}

output "application_insights_id" {
  value = azurerm_application_insights.this.id
  description = "The ID of the Application Insights instance"
}

output "notebook_url" {
 value = databricks_notebook.this.url
}

output "job_url" {
  value = databricks_job.this.url
}