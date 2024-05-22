# Retrieve information about the current user.
data "databricks_current_user" "me" {
    depends_on = [
        azurerm_databricks_workspace.this
    ]
}

# Create the cluster with the "smallest" amount
# of resources allowed.
data "databricks_node_type" "smallest" {
    local_disk = true
    depends_on = [
        azurerm_databricks_workspace.this
    ]
}

# Use the latest Databricks Runtime
# Long Term Support (LTS) version.
data "databricks_spark_version" "latest_lts" {
    long_term_support = true
    depends_on = [
        azurerm_databricks_workspace.this
    ]
}