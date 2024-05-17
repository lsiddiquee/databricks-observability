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
