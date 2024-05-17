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

# Cluster related variables
variable "cluster_name" {
  description = "A name for the cluster."
  type        = string
  default     = "My Cluster"
}

variable "cluster_autotermination_minutes" {
  description = "How many minutes before automatically terminating due to inactivity."
  type        = number
  default     = 60
}

variable "cluster_num_workers" {
  description = "The number of workers."
  type        = number
  default     = 1
}

# Notebook related variables
variable "notebook_subdirectory" {
  description = "A name for the subdirectory to store the notebook."
  type        = string
  default     = "Terraform"
}

variable "notebook_filename" {
  description = "The notebook's filename."
  type        = string
}

variable "notebook_source_path" {
  description = "The source path of the notebook."
  type        = string
}

variable "notebook_language" {
  description = "The language of the notebook."
  type        = string
}

#Job related variables
variable "job_name" {
  description = "A name for the job."
  type        = string
  default     = "My Job"
}

variable "task_key" {
  description = "A name for the task."
  type        = string
  default     = "my_task"
}
