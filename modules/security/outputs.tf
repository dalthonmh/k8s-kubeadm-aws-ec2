output "security_group_id" {
  value = aws_security_group.aws-linux-sg.id
}
output "key_name" {
  value = aws_key_pair.key_pair.key_name
}
output "ssh_key_file" {
  value = local_sensitive_file.ssh_key.filename
}
output "ssh_private_key" {
  value     = tls_private_key.key_pair.private_key_openssh
  sensitive = true
}
