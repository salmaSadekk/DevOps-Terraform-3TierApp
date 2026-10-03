variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_from_port" {
  description = "Ingress starting port"
  type        = number
}

variable "ingress_to_port" {
  description = "Ingress ending port"
  type        = number
}

variable "ingress_protocol" {
  description = "Ingress protocol"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the security group"
  type        = list(string)
  default     = null
}

variable "ingress_security_groups" {
  description = "Security groups allowed to access this security group"
  type        = list(string)
  default     = null
}

variable "egress_from_port" {
  description = "Egress starting port"
  type        = number
  default     = 0
}

variable "egress_to_port" {
  description = "Egress ending port"
  type        = number
  default     = 0
}

variable "egress_protocol" {
  description = "Egress protocol"
  type        = string
  default     = "-1"
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks allowed for outbound traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}