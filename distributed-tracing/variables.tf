variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region in which to create the resources"
  type        = string
}

variable "databricks_workspace_name" {
  description = "The name of the Databricks workspace"
  type        = string
}

variable "application_insights_name" {
  description = "The name of the Application Insights instance"
  type        = string
}
