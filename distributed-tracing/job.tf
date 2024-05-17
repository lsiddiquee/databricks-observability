resource "databricks_job" "this" {
  name = var.job_name
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
