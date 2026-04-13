###################################
## Virtual Machine Module - Main ##
###################################

# Create EC2 Instances from node map
resource "aws_instance" "nodes" {
  for_each = var.nodes

  ami                         = data.aws_ami.server_ami.id
  instance_type               = try(each.value.instance_type, var.linux_instance_type)
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.linux_associate_public_ip_address
  source_dest_check           = false
  key_name                    = var.key_name
  user_data                   = file("${path.module}/aws-user-data.sh")

  # root disk
  root_block_device {
    volume_size           = try(each.value.root_volume_size, var.linux_root_volume_size)
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_size           = try(each.value.data_volume_size, var.linux_data_volume_size)
    volume_type           = var.linux_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-${each.key}"
    Environment = var.app_environment
    Role        = try(each.value.role, "worker")
  }
}

# Create Elastic IPs
resource "aws_eip" "nodes" {
  for_each = var.nodes

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-${each.key}-eip"
    Environment = var.app_environment
  }
}

# Associate Elastic IPs
resource "aws_eip_association" "nodes" {
  for_each = var.nodes

  instance_id   = aws_instance.nodes[each.key].id
  allocation_id = aws_eip.nodes[each.key].id
}
