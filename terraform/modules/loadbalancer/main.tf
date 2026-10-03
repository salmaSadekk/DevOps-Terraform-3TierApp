resource "aws_lb" "demo-alb" {
    name = var.name
    internal = "false"
    load_balancer_type = "application"
    security_groups = [var.SG]
    subnets = var.subnet_ids
}

resource "aws_lb_target_group" "demo-target" {
    name = var.demotarget_name
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc
   /* health_check {
      path = "/health"
      port = 80
      protocol = "HTTP"
    } */
}




resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.demo-alb.arn
    port = 80  
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.demo-target.arn
    }
}


/* 
resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Allow traffic for Load balancer"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic from anywhere
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH traffic from anywhere
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outgoing traffic for anny protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

   vpc_id      = var.vpc
} */