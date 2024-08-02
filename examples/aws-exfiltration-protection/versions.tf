terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }

    aws = {
      source = "hashicorp/aws"
    }
  }
}



provider "databricks" {
  host          = "https://accounts.cloud.databricks.com"
  client_id     = "2c672915-6969-46f8-943f-4e2630a8161a"
  client_secret = "dose53a3a964b082128e1457eafc0d00066c"
  account_id    = "0d26daa6-5e44-4c97-a497-ef015f91254a"
}