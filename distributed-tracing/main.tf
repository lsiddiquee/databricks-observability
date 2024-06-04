terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.104.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.44.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "azurerm" {
  skip_provider_registration=true
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  application_type    = "web"
}

resource "azurerm_databricks_workspace" "this" {
  name                = var.databricks_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "standard"
}

provider "databricks" {
  host                        = azurerm_databricks_workspace.this.workspace_url
  azure_workspace_resource_id = azurerm_databricks_workspace.this.id
}

resource "local_file" "dotenv_file" {
  filename = "${var.app_subdirectory}/.env"
  content  = templatefile("${var.app_subdirectory}/${var.app_dotenv_template_filename}", {
    app_insights_connection_string = azurerm_application_insights.this.connection_string,
    databricks_host = "https://${azurerm_databricks_workspace.this.workspace_url}",
    databricks_token = databricks_token.this.token_value,
    databricks_job_id = databricks_job.this.id
  })
}