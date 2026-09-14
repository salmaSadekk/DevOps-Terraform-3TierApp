resource "aws_lb" "demo-alb" {
    name = "demo-alb"
    internal = "false"
    load_balancer_type = "application"
    security_groups = [aws_security_group.demo-sg.id]
    subnets = var.public_subnet
}

resource "aws_lb_target_group" "demo-target" {
    name = "demo-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.demo-vpc.id
    health_check {
      path = "/health"
      port = 80
      protocol = "HTTP"
    }
}

resource "aws_lb_target_group_attachment" "demo2" {
  target_group_arn = aws_lb_target_group.demo-target.arn
  target_id        = aws_instance.demo2.id
  port             = 80
  depends_on = [
    aws_lb_target_group.demo-target,
    aws_instance.demo2,
  ]
}

resource "aws_lb_target_group_attachment" "demo3" {
  target_group_arn = aws_lb_target_group.demo-target.arn
  target_id        = aws_instance.demo3.id
  port             = 80
  depends_on = [
    aws_lb_target_group.demo-target,
    aws_instance.demo3,
  ]
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


resource "aws_security_group" "asg_sg" {
  name        = "asg-security-group"
  description = "Allow traffic for the Auto Scaling Group instances"
  
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
}