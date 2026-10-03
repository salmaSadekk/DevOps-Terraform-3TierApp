variable "vpc" {
  description = "VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet where the EC2 instance will be created"
  type = list(string)
}

variable "demotarget_name" {
  description = "name of target group"
  type = string
}

variable SG {}

variable name {}