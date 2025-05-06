output "public_ec2_ip" {
  description = "IP público da instância EC2 pública"
  value       = aws_instance.public_ec2.public_ip
}

output "private_ec2_ips" {
  description = "IPs privados das instâncias privadas EC2 (count = 3)"
  value       = [for instance in aws_instance.private_ec2 : instance.private_ip]
}

output "private_database_ip" {
  description = "IP privado da instância de banco de dados"
  value       = aws_instance.private_ec2_database.private_ip
}
