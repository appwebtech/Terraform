provider "aws" {
  region = "eu-west-1"
}

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
    from_port   = 8080
    to_port     = 8080
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

  tags = {
    Name : "Webserver SG"
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

# ELB SG
resource "aws_security_group" "kaseo-alb" {
  name        = "alb-sg"
  description = "Allow TLS traffic to webservers"
  vpc_id      = aws_vpc.kaseo-restaurant-ltd.id
  # Ingress
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB SG"
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

# Launch configuration
resource "aws_launch_configuration" "kaseo-launch-config" {
  name          = "web_config"
  image_id      = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro"
  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "kaseo-autoscaling" {
  name                      = "kaseo-restaurants-manchester"
  availability_zones        = ["eu-west-1a", "eu-west-1b"]
  min_size                  = 2
  max_size                  = 6
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  launch_configuration      = aws_launch_configuration.kaseo-launch-config.name

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "name"
    value               = "kaseo-manchester-ag"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

# ALB Bucket to store Logs
resource "aws_s3_bucket" "kaseo-restaurant-logs" {
  bucket = "kaseo-logs-from-alb"
  acl    = "private"
  tags = {
    Name = "Kaseo Restaurant"
    Area = "Manchester"
  }
}

# ALB
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "kaseo-restaurants-alb"

  load_balancer_type = "application"

  vpc_id          = aws_vpc.kaseo-restaurant-ltd.id
  subnets         = ["subnet-066a1d3ba010d66be", "subnet-0fd15976c2f016b7e"]
  security_groups = ["sg-0dc8d12f43eb37fc0"]

  access_logs = {
    bucket = "kaseo-restaurant-logs"
  }

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          target_id = ""
          port      = 80
        },
        {
          target_id = ""
          port      = 8080
        }
      ]
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = ""
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Name = "Kaseo Restaurants Manchester"
  }
}

output "SG" {
  value = aws_security_group.kaseo-alb.id
}
output "subnet-1" {
  value = aws_subnet.kaseo-public-sub-1.id
}
output "subnet-2" {
  value = aws_subnet.kaseo-public-sub-2.id
}

# MySQL DB
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "kaseodb"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.large"
  allocated_storage = 5

  name     = "kaseodb"
  username = "joseph"
  password = "NotaRealPassword"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = ["sg-0cedddd2a457c94fc"]

  maintenance_window = "Mon:00:00-Mon:02:00"
  backup_window      = "03:00-04:00"

  monitoring_interval    = "30"
  monitoring_role_name   = "Kaseo-RDS-Monitoring-Role"
  create_monitoring_role = true
  multi_az               = true

  tags = {
    Owner       = "KaseoDB"
    Environment = "Manchester"
  }

  subnet_ids = ["subnet-0f80b56f22f99864d", "subnet-0f4413354d1be32fa"]

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "kaseo-snapshot"

  # Database Deletion Protection
  deletion_protection = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}
