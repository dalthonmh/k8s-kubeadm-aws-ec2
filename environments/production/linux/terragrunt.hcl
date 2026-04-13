# ---------------------------------------------------------------------------------------------------------------------
# LINUX EC2 MODULE - PRODUCTION
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
    "master-1" = { role = "master", instance_type = "t3.medium", root_volume_size = 30 }
    "worker-1" = { role = "worker" }
    "worker-2" = { role = "worker" }
  }

  # Default EC2 settings (overridable per node)
  linux_instance_type               = "t3.small"
  linux_associate_public_ip_address = true
  linux_root_volume_size            = 20
  linux_data_volume_size            = 10
  linux_root_volume_type            = "gp3"
  linux_data_volume_type            = "gp3"

  # From dependencies
  subnet_id         = dependency.network.outputs.public_subnet_id
  security_group_id = dependency.security.outputs.security_group_id
  key_name          = dependency.security.outputs.key_name

  # AMI - Debian official
  ami_owners      = ["136693071363"]
  ami_filter_name = "debian-13-amd64-*"
}
