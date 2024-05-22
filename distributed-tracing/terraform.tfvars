resource_group_name        = "rg_distributed_tracing_sample"
location                   = "West Europe"
databricks_workspace_name  = "adb_ws_distributed_tracing_sample"
application_insights_name  = "appinsights_distributed_tracing_sample"

cluster_name                    = "Distributed Tracing Cluster"
cluster_autotermination_minutes = 60
cluster_num_workers             = 1

notebook_subdirectory = "distributed_tracing_sample"
notebook_filename     = "distributed_tracing"
notebook_source_path  = "notebooks/distributed_tracing.py.tftpl"
notebook_language     = "PYTHON"

job_name = "Distributed Tracing Job"
task_key = "distributed_tracing_task_key"

webapp_service_plan_name = "webapp-service-plan-distributed-tracing-sample"
webapp_name              = "webapp-distributed-tracing-sample"