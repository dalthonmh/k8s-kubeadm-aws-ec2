# ---------------------------------------------------------------------------------------------------------------------
# LINUX EC2 MODULE - LOCALSTACK
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  source = "../../../modules//linux"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    public_subnet_id = "subnet-mock-12345"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security" {
  config_path = "../security"

  mock_outputs = {
    security_group_id = "sg-mock-12345"
    key_name          = "mock-key"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  # Cluster nodes
  nodes = {
    "master-1" = { role = "master" }
    "worker-1" = { role = "worker" }
    "worker-2" = { role = "worker" }
  }

  # Default EC2 settings (overridable per node)
  linux_instance_type               = "t2.micro"
  linux_associate_public_ip_address = true
  linux_root_volume_size            = 8
  linux_data_volume_size            = 8
  linux_root_volume_type            = "gp2"
  linux_data_volume_type            = "gp2"

  # From dependencies
  subnet_id         = dependency.network.outputs.public_subnet_id
  security_group_id = dependency.security.outputs.security_group_id
  key_name          = dependency.security.outputs.key_name

  # AMI - LocalStack mock owners
  ami_owners      = ["136693071363", "000000000000"]
  ami_filter_name = "debian-13-amd64-*"
}
