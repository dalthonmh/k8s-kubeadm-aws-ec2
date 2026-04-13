output "instance_ids" {
  description = "Map of node name to instance ID"
  value       = { for k, v in aws_instance.nodes : k => v.id }
}

output "public_ips" {
  description = "Map of node name to public IP"
  value       = { for k, v in aws_instance.nodes : k => v.public_ip }
}

output "public_dns" {
  description = "Map of node name to public DNS"
  value       = { for k, v in aws_instance.nodes : k => v.public_dns }
}

output "eip_public_ips" {
  description = "Map of node name to Elastic IP"
  value       = { for k, v in aws_eip.nodes : k => v.public_ip }
}

output "ssh_commands" {
  description = "Ready-to-use SSH commands for each node"
  value = {
    for k, v in aws_eip.nodes : k => "ssh -i ~/.ssh/${var.key_name}.pem admin@${v.public_ip}"
  }
}
