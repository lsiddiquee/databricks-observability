output "resource_group_name" {
  value = azurerm_resource_group.this.name
  description = "The name of the resource group"
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.this.id
  description = "The ID of the Databricks workspace"
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
  description = "The URL of the Databricks workspace"
}

output "application_insights_id" {
  value = azurerm_application_insights.this.id
  description = "The ID of the Application Insights instance"
}

output "cluster_url" {
 value = databricks_cluster.this.url
}

output "notebook_url" {
 value = databricks_notebook.this.url
}

output "job_url" {
  value = databricks_job.this.url
}

output "adb_job_id" {
  value = databricks_job.this.id
  description = "The ID of the Databricks job"
}