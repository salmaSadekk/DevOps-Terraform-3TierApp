module "vpc" {
  source         = "./modules/vpc"
  region         = var.region
  cidr_block     = var.cidr_block
  private_subnet = var.private_subnet
  public_subnet  = var.public_subnet
  azs            = var.azs
}
/*

module "ec2" {
  source = "./modules/ec2"

  ami_id        = "ami-0f2f6d6f49dbe9fd1"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  instance_name = "terraform-ec2"
}

*/


module "loadbalancer" {
  source = "./modules/loadbalancer"
  vpc = module.vpc.my_vpc
  subnet_ids  = var.public_subnet



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
   alb_security_group_id = module.loadbalancer.securityGroup
   targetgroup_alb_arn = module.loadbalancer.target_group_arn


}
