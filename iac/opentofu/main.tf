########################################
# Terraform Global Configuration
########################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "tpe-lab-iac-showroom-backend"
    key    = "opentofu/terraform.tfstate"
    region = "eu-north-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}

########################################
# Resources creation
########################################

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ot-vpc"
    Project = "iac-showroom"
    IaC  = "opentofu"
  }
}

# Create a Subnet
resource "aws_subnet" "front" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "ot-subnet-front"
    Project = "iac-showroom"
    IaC  = "opentofu"
  }
}

# Instance Security group
resource "aws_security_group" "ec2" {
  name        = "ec2_security_group"
  description = "Allows inbound access from the ALB only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2" {
  ami           = "ami-0705384c0b33c194c" # Ubuntu 22.04
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.front.id
  vpc_security_group_ids = [ aws_security_group.ec2.id ]

  tags = {
    Name = "ot-ec2-web"
    Project = "iac-showroom"
    IaC  = "opentofu"
  }
}