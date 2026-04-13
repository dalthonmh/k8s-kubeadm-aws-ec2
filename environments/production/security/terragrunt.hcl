# ---------------------------------------------------------------------------------------------------------------------
# SECURITY MODULE - PRODUCTION
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  source = "../../../modules//security"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id   = "vpc-mock-12345"
    vpc_cidr = "10.1.64.0/18"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  vpc_id   = dependency.network.outputs.vpc_id
  vpc_cidr = dependency.network.outputs.vpc_cidr
}
