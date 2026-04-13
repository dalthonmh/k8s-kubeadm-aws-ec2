variable "app_name" {
  type        = string
  description = "Application name"
}

variable "app_environment" {
  type        = string
  description = "Application environment"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

# Added vpc_id variable so Security Group knows where to be created
variable "vpc_id" {
  type        = string
  description = "ID of the VPC where to create security group"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC (for internal-only rules)"
  default     = "10.1.64.0/18"
}

variable "ssh_key_path" {
  type        = string
  description = "Directory where the SSH private key will be saved"
  default     = "~/.ssh"
}
