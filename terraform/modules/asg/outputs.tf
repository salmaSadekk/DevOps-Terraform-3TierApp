output "asgname" {
  value = aws_autoscaling_group.terraform_asg.name
}


output "SG_ASG_id" {
  value = aws_security_group.asg_sg.id
}