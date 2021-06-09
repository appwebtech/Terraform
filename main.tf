provider "aws" {
  region = "eu-west-1"
}

# Variables
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
variable "my_ip" {}
variable "instance_type" {}

# VPC
resource "aws_vpc" "kaseo-restaurant-ltd" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.kaseo-vpc}"
  }
}

# Subnets
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

# Internet Gateway
resource "aws_internet_gateway" "kaseo-igw" {
  vpc_id = aws_vpc.kaseo-restaurant-ltd.id
  tags = {
    Name : "kaseo-rtb"
  }
}

# Route Table
resource "aws_route_table" "kaseo-route-table" {
  vpc_id = aws_vpc.kaseo-restaurant-ltd.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kaseo-igw.id
  }
  tags = {
    Name : "kaseo-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet-a" {
  subnet_id      = aws_subnet.kaseo-public-sub-1.id
  route_table_id = aws_route_table.kaseo-route-table.id
}
resource "aws_route_table_association" "a-rtb-subnet-b" {
  subnet_id      = aws_subnet.kaseo-public-sub-2.id
  route_table_id = aws_route_table.kaseo-route-table.id
}

# Security Groups (SG)
# Web server SG
resource "aws_security_group" "kaseo-web-server-sg" {
  name   = "web-server-sg"
  vpc_id = aws_vpc.kaseo-restaurant-ltd.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    description = "RDP"
    cidr_blocks = [var.my_ip]
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name : "ALB SG"
  }

}

# Database SG
resource "aws_security_group" "kaseo-db" {
  name        = "db-sg"
  description = "Allow TLS traffic from web-server"
  vpc_id      = aws_vpc.kaseo-restaurant-ltd.id
  # Ingress
  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  tags = {
    Name = "DB SG"
  }
}

# EC2 Instance
# Fetch instance data
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
# Create Instance
resource "aws_instance" "kaseo-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.kaseo-public-sub-1.id
  vpc_security_group_ids = [aws_security_group.kaseo-web-server-sg.id]
  availability_zone      = "eu-west-1a"

  associate_public_ip_address = true
  key_name                    = "kwa-kaseo"
  tags = {
    Name = "Kaseo Webserver"
  }
}

# Create ALB
resource "aws_elb" "kaseo-alb" {
  name               = "kase-manchester-alb"
  availability_zones = ["eu-west-1a", "us-west-1b"]

  access_logs {
    bucket        = "kaseo-alb-logs"
    bucket_prefix = "manchester"
    interval      = 60
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = ""
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [data.aws_ami.latest-amazon-linux-image.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "kaseo-restaurants-elb"
  }
}

resource "aws_eip" "lb" {
  instance = data.aws_ami.latest-amazon-linux-image.id
  vpc      = true
}


# Outputs
output "vpc-id" {
  value = aws_vpc.kaseo-restaurant-ltd.id
}
output "db-id-AZ-1" {
  value = aws_subnet.kaseo-private-db-1.id
}
output "db-id-AZ-2" {
  value = aws_subnet.kaseo-private-db-2.id
}
output "aws-ami-id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}
