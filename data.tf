data "aws_vpc" "networking-VPC" {
  tags = {
    Name = "Project VPC"
  }
}

data "aws_subnets" "vpc" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.networking-VPC.id]
  }
}

data "aws_availability_zones" "available" {
    state = "available"
}
