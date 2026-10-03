output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.myec2.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.myec2.public_ip
}