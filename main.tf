provider "aws" {
  region = "eu-west-1"
}

variable "vpc_cidr_block" {
  default = "vpc_cidr_block"
}
variable "kaseo-vpc" {
  description = "kaseo manchester area"
}
variable "cidr_blocks-subnets" {
  description = "cidr blocks for subnets"
  type = list(object({
    cidr_block = string
    name       = string
  }))
}

resource "aws_vpc" "kaseo-restaurant-ltd" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : var.kaseo-vpc
  }
}

resource "aws_subnet" "kaseo-public-sub-1" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[0].cidr_block
  availability_zone = "eu-west-1a"
  tags = {
    Name : "ALB Subnet AZ A"
  }
}

resource "aws_subnet" "kaseo-public-sub-2" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[1].cidr_block
  availability_zone = "eu-west-1b"
  tags = {
    Name : "ALB Subnet AZ B"
  }
}

resource "aws_subnet" "kaseo-private-sub-1" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[2].cidr_block
  availability_zone = "eu-west-1a"
  tags = {
    Name : "App Subnet AZ A",
    Servers : "Apache and Nginx"
  }
}

resource "aws_subnet" "kaseo-private-sub-2" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[3].cidr_block
  availability_zone = "eu-west-1b"
  tags = {
    Name : "App Subnet AZ B",
    Servers : "Apache and Nginx"
  }
}

resource "aws_subnet" "kaseo-private-db-1" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[4].cidr_block
  availability_zone = "eu-west-1a"
  tags = {
    Name : "DB Subnet AZ A",
    DB : "DynamoDB"
  }
}

resource "aws_subnet" "kaseo-private-db-2" {
  vpc_id            = aws_vpc.kaseo-restaurant-ltd.id
  cidr_block        = var.cidr_blocks-subnets[5].cidr_block
  availability_zone = "eu-west-1b"
  tags = {
    Name : "DB Subnet AZ B",
    DB : "DynamoDB"
  }
}

output "vpc-id" {
  value = aws_vpc.kaseo-restaurant-ltd.id
}
output "db-id-AZ-1" {
  value = aws_subnet.kaseo-private-db-1.id
}
output "db-id-AZ-2" {
  value = aws_subnet.kaseo-private-db-2.id
}
