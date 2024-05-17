resource "databricks_notebook" "this" {
  path     = "${data.databricks_current_user.me.home}/${var.notebook_subdirectory}/${var.notebook_filename}"
  language = var.notebook_language
  content_base64  = base64encode(templatefile("./${var.notebook_source_path}", {
    app_insights_conn_str = azurerm_application_insights.this.connection_string
  }))
}
