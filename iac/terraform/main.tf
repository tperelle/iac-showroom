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
    key    = "terraform/terraform.tfstate"
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
    Name = "tf-vpc"
    Project = "iac-showroom"
    IaC  = "terraform"
  }
}

# Create a Subnet
resource "aws_subnet" "front" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "tf-subnet-front"
    Project = "iac-showroom"
    IaC  = "terraform"
  }
}

# # Search the Ubuntu AMI
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

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
    Name = "tf-ec2-web"
    Project = "iac-showroom"
    IaC  = "terraform"
  }
}