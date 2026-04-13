# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT ROOT CONFIGURATION - LOCALSTACK
# ---------------------------------------------------------------------------------------------------------------------
# All child modules (network, security, linux) include this file.
#
# Usage:
#   cd environments/localstack
#   terragrunt run --all init
#   terragrunt run --all apply
# ---------------------------------------------------------------------------------------------------------------------

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  aws_region          = local.env_vars.locals.aws_region
  app_name            = local.env_vars.locals.app_name
  app_environment     = local.env_vars.locals.app_environment
  localstack_endpoint = try(local.env_vars.locals.localstack_endpoint, "http://localhost:4566")
}

# The env.hcl is in the same directory as this file, but child modules call
# find_in_parent_folders("env.hcl") which walks up from their directory and
# finds it here.

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region                      = "${local.aws_region}"
      access_key                  = "test"
      secret_key                  = "test"
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true
      s3_use_path_style           = true

      endpoints {
        ec2 = "${local.localstack_endpoint}"
        iam = "${local.localstack_endpoint}"
        sts = "${local.localstack_endpoint}"
        s3  = "${local.localstack_endpoint}"
      }
    }
  EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE BACKEND CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "local" {}
    }
  EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# COMMON INPUTS — inherited by all child modules
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  app_name        = local.app_name
  app_environment = local.app_environment
  aws_region      = local.aws_region
}
