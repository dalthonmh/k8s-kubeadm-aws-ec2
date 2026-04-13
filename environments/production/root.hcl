# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT ROOT CONFIGURATION - PRODUCTION
# ---------------------------------------------------------------------------------------------------------------------
# All child modules (network, security, linux) include this file.
#
# Usage:
#   cd environments/production
#   terragrunt run --all init
#   terragrunt run --all apply
# ---------------------------------------------------------------------------------------------------------------------

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  aws_region      = local.env_vars.locals.aws_region
  app_name        = local.env_vars.locals.app_name
  app_environment = local.env_vars.locals.app_environment
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
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
