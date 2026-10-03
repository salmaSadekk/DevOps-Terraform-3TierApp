resource "aws_autoscaling_group" "terraform_asg" {
  name               = var.name  # This is the name of the ASG that will be created in AWS
  min_size           = var.min_size  # Reference the variable 'min_size' to define the lower bound of the ASG size
  max_size           = var.max_size  # Reference the variable 'max_size' to define the upper bound of the ASG size
  desired_capacity   = var.desired_capacity  # Reference the variable 'desired_capacity' to set the number of instances at the start
  vpc_zone_identifier = var.subnet_ids # Reference the variable 'availability_zones' to define where to deploy instances in different zones
  launch_template {
    id      = aws_launch_template.launch-asg.id  # Reference the ID of the launch template defined elsewhere in your configuration
    version = "$Latest"  # Use the latest version of the launch template when launching instances
  }

  target_group_arns = [
  var.targetgroup_alb_arn
]

}



resource "aws_launch_template" "launch-asg" {
  name          = var.security_group_name
  image_id      = var.ami_id
  instance_type = var.instance_type


  vpc_security_group_ids = [
    aws_security_group.asg_sg.id
  ]



  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "MyLaunchASGInstance"
    }
  } 
  
  }

  resource "aws_security_group" "asg_sg" {
  name        = var.security_group_name
  description = "Allow traffic for ASG"
  
   ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.SG]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   vpc_id      = var.vpc

  tags = {
    Name = var.security_group_name
  }

}

