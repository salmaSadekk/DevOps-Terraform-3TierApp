output "securityGroup" {
  value = aws_security_group.lb_sg.id
}


output "target_group_arn" {
   value = aws_lb_target_group.demo-target.arn
}