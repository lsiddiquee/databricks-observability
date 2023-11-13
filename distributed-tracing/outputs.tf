output "resource_group_name" {
  value = azurerm_resource_group.example.name
  description = "The name of the resource group"
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.example.id
  description = "The ID of the Databricks workspace"
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.example.workspace_url
  description = "The URL of the Databricks workspace"
}

output "application_insights_id" {
  value = azurerm_application_insights.example.id
  description = "The ID of the Application Insights instance"
}
