resource "databricks_cluster" "this" {
  cluster_name            = var.cluster_name
  node_type_id            = data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.latest_lts.id
  autotermination_minutes = var.cluster_autotermination_minutes
  num_workers             = var.cluster_num_workers
  depends_on = [
      azurerm_databricks_workspace.this
  ]
}

resource "databricks_notebook" "this" {
  path     = "${data.databricks_current_user.me.home}/${var.notebook_subdirectory}/${var.notebook_filename}"
  language = var.notebook_language
  content_base64  = base64encode(templatefile("./${var.notebook_source_path}", {
    app_insights_conn_str = azurerm_application_insights.this.connection_string
  }))
  depends_on = [
      azurerm_databricks_workspace.this
  ]
}

resource "databricks_job" "this" {
  name = var.job_name
  parameter {
    name = "traceparent"
    default = "00-80e1afed08e019fc1110464cfa66635c-7a085853722dc6d2-01"
  }
  task {
    task_key = var.task_key
    existing_cluster_id = databricks_cluster.this.cluster_id
    notebook_task {
      notebook_path = databricks_notebook.this.path
    }
  }
  email_notifications {
    on_success = [ data.databricks_current_user.me.user_name ]
    on_failure = [ data.databricks_current_user.me.user_name ]
  }
}

resource "databricks_token" "this" {
  comment          = "Token to authenticate with Databricks"
  depends_on = [
      azurerm_databricks_workspace.this
  ]
}