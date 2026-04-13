# ---------------------------------------------------------------------------------------------------------------------
# NETWORK MODULE - LOCALSTACK
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  source = "../../../modules//network"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  aws_az             = "us-east-1a"
  vpc_cidr           = "10.1.64.0/18"
  public_subnet_cidr = "10.1.64.0/24"
}
