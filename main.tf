terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "steve-weaver-demo-org"

    workspaces {
      name = "TF-Cloudability-0925"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-0de716d6197524dd9" # This is a publicly available Amazon Linux 2 AMI
  instance_type = "t2.small"
  tags = {
    Name = "HelloWorldServer"
    cost-center = "dev"
  }
}

#resource "aws_s3_bucket" "app_data" {
#  bucket = "hcp-demo-app-data-${random_pet.bucket_suffix.id}"
#  tags = {
#    Environment = "Demo"
#    Purpose     = "CostEstimation"
#  }
#}
#resource "random_pet" "bucket_suffix" {
#  length    = 2
#  separator = "-"
#}

resource "aws_ebs_volume" "web_data" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
  tags = {
    Name = "WebDataVolume"
    cost-center = "dev"
  }
}

resource "aws_volume_attachment" "web_data_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_data.id
  instance_id = aws_instance.web.id
}

resource "aws_db_instance" "app_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "appdb"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
  tags = {
    cost-center = "dev"
  }
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use the first two subnets for the load balancer
locals {
  lb_subnets = slice(data.aws_subnets.default_vpc_subnets.ids, 0, 2)
}

resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = []
  subnets            = local.lb_subnets
  tags = {
    Environment = "Demo"
    cost-center = "dev"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  tags = {
    cost-center = "dev"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
  tags = {
    cost-center = "dev"
  }
}
