# ---------------------------------------------------------------------------------------------------------------------
# LOCALSTACK ENVIRONMENT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
locals {
  aws_region      = "us-east-1"
  app_name        = "postula"
  app_environment = "local"
  is_localstack   = true

  localstack_endpoint = "http://localhost.localstack.cloud:4566"
}
