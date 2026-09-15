variable "vpc" {
  description = "VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet where the EC2 instance will be created"
  type = list(string)
}

