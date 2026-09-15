variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
}

variable "subnet_ids" {
  description = "Subnet where the EC2 instance will be created"
  type = list(string)
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "terraform-ec2"
}

variable "min_size" {
  description = "Min size"
  type        = string
  default     = "t2.micro"
}

variable "max_size" {
  description = "Max size"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity"
  type        = string
}

variable "vpc" {
  description = "VPC"
  type        = string
}


variable "alb_security_group_id" {
  description = "SG"
  type        = string
}


variable "targetgroup_alb_arn" {
  description = "ALB_arn"
  type        = string
}
