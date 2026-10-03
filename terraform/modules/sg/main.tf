resource "aws_security_group" "this" {
  name        = var.sg_name
  description = "Security group for ${var.sg_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_cidr_blocks != null ? [1] : []

    content {
      from_port   = var.ingress_from_port
      to_port     = var.ingress_to_port
      protocol    = var.ingress_protocol
      cidr_blocks = var.ingress_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_security_groups != null ? [1] : []

    content {
      from_port       = var.ingress_from_port
      to_port         = var.ingress_to_port
      protocol        = var.ingress_protocol
      security_groups = var.ingress_security_groups
    }
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = {
    Name = var.sg_name
  }
}