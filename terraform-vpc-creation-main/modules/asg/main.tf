resource "aws_autoscaling_group" "terraform_asg" {
  name               = "my-terraform-asg"  # This is the name of the ASG that will be created in AWS
  min_size           = var.min_size  # Reference the variable 'min_size' to define the lower bound of the ASG size
  max_size           = var.max_size  # Reference the variable 'max_size' to define the upper bound of the ASG size
  desired_capacity   = var.desired_capacity  # Reference the variable 'desired_capacity' to set the number of instances at the start
  vpc_zone_identifier = var.subnet_ids # Reference the variable 'availability_zones' to define where to deploy instances in different zones
  launch_template {
    id      = aws_launch_template.launch-asg.id  # Reference the ID of the launch template defined elsewhere in your configuration
    version = "$Latest"  # Use the latest version of the launch template when launching instances
  }

}



resource "aws_launch_template" "launch-asg" {
  name          = "my-launch-asg"
  image_id      = var.ami_id
  instance_type = var.instance_type


  vpc_security_group_ids = [
    var.asg_sg.id
  ]


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "MyLaunchASGInstance"
    }
  } 
  
  }

