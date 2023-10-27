terraform {
  backend "s3" {
    bucket                  = "dc11-cntnghia-devopstraining-apache2log"
    dynamodb_table          = "terraform-state-lock-dynamo"
    key                     = "my-terraform-project"
    region                  = "ap-southeast-1"
    access_key 		          = "AKIARSFY4H7OQKOLYL5R"
	  secret_key 	            = "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"
  }
  required_providers {
    aws = {
      source  = "local/hashicorp/aws"
      version = "5.22.0"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region                    = "ap-southeast-1"
  access_key 		            = "AKIARSFY4H7OQKOLYL5R"
  secret_key 	              = "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"
}
resource "aws_s3_bucket" "New_bucket" {
  bucket = "dc11-cntnghia-devopstraining-newbucket"

  tags = {
    Name = "myBucketTagName"
  }
}

data "aws_availability_zones" "available" {}
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    assign_generated_ipv6_cidr_block = true
    tags = {
        Name = "Project VPC"
    }
}
variable "private_cidrs" {
    default = ["10.0.2.0/24", "10.0.3.0/24"]
}
variable "public_cidrs" {
    default = ["10.0.0.0/24", "10.0.1.0/24"]
}
resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnet_cidrs)
    cidr_block = var.public_subnet_cidrs[count.index]
    vpc_id = aws_vpc.vpc.id
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags = {
        Name = "public${count.index}"
    }
}
resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet_cidrs)
    cidr_block = var.private_subnet_cidrs[count.index]
    vpc_id = aws_vpc.vpc.id
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags = {
        Name = "private${count.index}"
    }
}
resource "aws_eip" "neip"  {
   count = length(var.private_subnet_cidrs) 
   vpc   = true
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "main"
  }
}
resource "aws_nat_gateway" "nat" {
   count         = length(var.private_subnet_cidrs) 
   subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
   allocation_id = element(aws_eip.neip.*.id, count.index)
   
   depends_on    = [aws_internet_gateway.igw]
}
resource "aws_egress_only_internet_gateway"  "egw"  {
   #count  = length(var.private_cidrs) 
   vpc_id = aws_vpc.vpc.id
}
# routes for public subnets
resource "aws_route_table" "public_route" {
   count = length(var.public_subnet_cidrs) 
   vpc_id = aws_vpc.vpc.id
}
resource "aws_route" "public_ipv4" {
   count           = length(aws_route_table.public_route) 
   route_table_id  = aws_route_table.public_route[count.index].id
   gateway_id  = aws_internet_gateway.igw.id
   destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "ipv6_public"  {
   count                   = length(aws_route_table.public_route) 
   route_table_id          = aws_route_table.public_route[count.index].id
   egress_only_gateway_id  = aws_egress_only_internet_gateway.egw.id
   destination_ipv6_cidr_block = "::/0"
}
resource "aws_route_table_association" "public_route" {
   count          = length(aws_route_table.public_route) 
   subnet_id      = aws_subnet.public_subnet[count.index].id
   route_table_id = aws_route_table.public_route[count.index].id
}
# routes for private subnets
resource "aws_route_table" "route" {
   count = length(var.private_subnet_cidrs) 
   vpc_id = aws_vpc.vpc.id
}
resource "aws_route" "ipv4" {
   count           = length(aws_route_table.route) 
   route_table_id  = aws_route_table.route[count.index].id
   nat_gateway_id  = aws_nat_gateway.nat[count.index].id
   #nat_gateway_id  = aws_nat_gateway.nat.id
   destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "ipv6"  {
   count                   = length(aws_route_table.route) 
   route_table_id          = aws_route_table.route[count.index].id
   egress_only_gateway_id  = aws_egress_only_internet_gateway.egw.id
   destination_ipv6_cidr_block = "::/0"
}
resource "aws_route_table_association" "route" {
   count          = length(aws_route_table.route) 
   subnet_id      = aws_subnet.private_subnet[count.index].id
   route_table_id = aws_route_table.route[count.index].id
}