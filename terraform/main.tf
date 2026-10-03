module "vpc" {
  source         = "./modules/vpc"
  region         = var.region
  cidr_block     = var.cidr_block
  private_subnet = var.private_subnet
  public_subnet  = var.public_subnet
  azs            = var.azs
  
}



module "loadbalancer" {
  name = "frontend-alb"
  source = "./modules/loadbalancer"
  vpc = module.vpc.my_vpc
  subnet_ids  = module.vpc.public_subnets
demotarget_name = "frontendtg"
SG = module.security_groups_frontbalancer.security_group_id

}



/*

resource "aws_security_group" "demo_sg01_sg" {
  name        = var.demo_sg01_sg_name
  //description = var.demo_sg01_sg_description
  vpc_id      = var.demo_sg01_sg_vpc
  ingress {
    //description      = var.demo_sg01_insgress_description
    from_port        = var.demo_sg01_ingress_from_port
    to_port          = var.demo_sg01_ingress_to_port
    protocol         = var.demo_sg01_ingress_protocol
    cidr_blocks      = [var.my_ip_address]
    }

  egress {
    from_port        = var.demo_sg01_egress_from_port
    to_port          = var.demo_sg01_egress_to_port
    protocol         = var.demo_sg01_egress_protocol
    cidr_blocks      = [var.demo_sg01_egress_cidr_block]
    }


}


resource "aws_security_group" "demo_sg02_sg" {
  name        = var.demo_sg02_sg_name
  //description = var.demo_sg02_sg_description
  vpc_id      = var.demo_sg02_sg_vpc

  ingress {
    //description      = var.demo_sg02_insgress_description
    from_port        = var.demo_sg02_ingress_from_port
    to_port          = var.demo_sg02_ingress_to_port
    protocol         = var.demo_sg02_ingress_protocol
    security_groups = [var.SG]
    }

  egress {
    from_port        = var.demo_sg02_egress_from_port
    to_port          = var.demo_sg02_egress_to_port
    protocol         = var.demo_sg02_egress_protocol
    cidr_blocks      = [var.demo_sg02_egress_cidr_block]
    }


}

*/




module "security_groups_frontbalancer" {
  source = "./modules/sg"

  sg_name = "SGfront"
  vpc_id  = module.vpc.my_vpc

  ingress_from_port = 80
  ingress_to_port   = 80
  ingress_protocol  = "tcp"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_from_port   = 0
  egress_to_port     = 0
  egress_protocol    = "-1"
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "security_groups_back" {
  source = "./modules/sg"

  sg_name = "SGback"
  vpc_id  = module.vpc.my_vpc

  ingress_from_port = 80
  ingress_to_port   = 80
  ingress_protocol  = "tcp"

  ingress_security_groups = [
    module.asg.SG_ASG_id
  ]

  egress_from_port   = 0
  egress_to_port     = 0
  egress_protocol    = "-1"
  egress_cidr_blocks = ["0.0.0.0/0"]
}



module "asg" {
  source = "./modules/asg"

  ami_id        = "ami-0f2f6d6f49dbe9fd1"
  instance_type = "t3.micro"
  subnet_ids     = module.vpc.private_subnets
   instance_name = "terraform-ec2"
   min_size = 1
   max_size = 3
   desired_capacity =1 
   vpc = module.vpc.my_vpc
   //alb_security_group_id = module.loadbalancer.securityGroup
   targetgroup_alb_arn = module.loadbalancer.target_group_arn
SG = module.security_groups_frontbalancer.security_group_id
name = "frontAsg"
security_group_name = "frontASGSG"
}

module "internal_loadbalancer" {
   name = "backend-alb"
  source = "./modules/loadbalancer"
  vpc = module.vpc.my_vpc
  subnet_ids  = module.vpc.private_subnets
demotarget_name = "backendtg"
SG = module.security_groups_back.security_group_id



}

module "backend_asg" {
  source = "./modules/asg"

  ami_id            = "ami-0f2f6d6f49dbe9fd1"
  instance_type     = "t3.micro"
  subnet_ids        = module.vpc.private_subnets
  instance_name     = "backend"

  min_size          = 1
  max_size          = 2
  desired_capacity  = 1
security_group_name = "backendASGSG"
  vpc                    = module.vpc.my_vpc
 // SG = module.asg.SG_ASG_id
  //alb_security_group_id  = module.loadbalancer.securityGroup
  targetgroup_alb_arn    = module.internal_loadbalancer.target_group_arn
//security_group_name = "backend"
name = "backasg"
SG = module.security_groups_back.security_group_id

}
