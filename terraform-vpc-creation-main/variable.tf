variable "region" {
    default = "eu-central-1"
}

variable "cidr_block" {
    default = "10.0.0.0/16"
}

variable "private_subnet" {
    type = list(string)
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    description = "private subnet"
}

variable "public_subnet" {
    type = list(string)
    default = ["10.0.5.0/24","10.0.6.0/24","10.0.7.0/24"]
    description = "Public subnet"
}

variable "azs" {
    type = list(string)
    description = "Availability Zones"
    default = [ "eu-central-1a", "eu-central-1b", "eu-central-1c" ] 
}