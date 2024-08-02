resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "${local.prefix}-network"
  security_group_ids = [aws_security_group.default_spoke_sg.id]
  subnet_ids         = aws_subnet.spoke_db_private_subnet[*].id
  vpc_id             = aws_vpc.spoke_vpc.id

  dynamic "vpc_endpoints" {
    for_each = var.enable_private_link ? [1] : []

    content {
      dataplane_relay = databricks_mws_vpc_endpoint.relay_vpce[*].vpc_endpoint_id
      rest_api        = databricks_mws_vpc_endpoint.backend_rest_vpce[*].vpc_endpoint_id
    }
  }
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root_storage_bucket.bucket
  storage_configuration_name = "${local.prefix}-storage"
}

## Adding 20 second timer to avoid Failed credential validation check
#resource "time_sleep" "wait" {
#  create_duration = "20s"
#  depends_on = [
#    aws_iam_role_policy.cross_account_policy
#  ]
#}

resource "databricks_mws_credentials" "this" {
  account_id       = var.databricks_account_id
  role_arn         = data.aws_iam_role.this.arn
  credentials_name = "${local.prefix}-creds"
}

resource "databricks_mws_workspaces" "this" {
  account_id     = var.databricks_account_id
  aws_region     = var.region
  workspace_name = local.prefix

  credentials_id             = databricks_mws_credentials.this.credentials_id
  storage_configuration_id   = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                 = databricks_mws_networks.this.network_id
  private_access_settings_id = databricks_mws_private_access_settings.pla.private_access_settings_id
  is_no_public_ip_enabled    = true

  token {
    comment = "Terraform token"
  }
}

data "databricks_metastore" "this" {
  name          = "apj-offsite"
}

resource "databricks_metastore_assignment" "this" {
  metastore_id = data.databricks_metastore.this.id
  workspace_id = databricks_mws_workspaces.this.workspace_id
}

data "databricks_user" "me" {
  user_name = "akash.s@databricks.com"
}

resource "databricks_mws_permission_assignment" "add_user" {
  workspace_id = databricks_mws_workspaces.this.workspace_id
  principal_id = data.databricks_user.me.id
  permissions  = ["ADMIN"]
  depends_on = [
    databricks_mws_workspaces.this
  ]
}

