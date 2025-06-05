terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "fcs_frontend" {
  ami           = "ami-0f5dd381e07b0943a"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-FRONTEND"
  }
}

resource "aws_instance" "fcs_backend" {
  ami           = "ami-01e89ce81fbe4acf2"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-BACKEND"
 }
}

resource "aws_instance" "fcs_database" {
  ami           = "ami-0e27c3a2c52a5ac69"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-DATABASE"
 }
}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "terraform_ec2_key"
  public_key = "${file("terraform_ec2_key.pub")}"
}