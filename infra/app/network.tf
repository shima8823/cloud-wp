####################
# VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
####################
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_ec2_wordpress"
  }
}

####################
# Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
####################
resource "aws_subnet" "my_subnet_pub_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = "ap-northeast-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet-1a"
  }
}

####################
# Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
####################
resource "aws_route_table" "my_pub_route_1a" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "pub-route-table"
  }
}

####################
# IGW
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
####################
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "igw"
  }
}

####################
# Route Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
####################
resource "aws_route" "my_pub_route_rule_1a" {
  route_table_id         = aws_route_table.my_pub_route_1a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

####################
# Route Rule Associcate Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
####################
resource "aws_route_table_association" "my_pub_route_rule_associate_subnet_1a" {
  subnet_id      = aws_subnet.my_subnet_pub_1a.id
  route_table_id = aws_route_table.my_pub_route_1a.id
}

####################
# Security Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
####################
resource "aws_security_group" "sg_ec2" {
  name        = "fw-ec2"
  description = "SG_EC2"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg_ec2_accept_80" {
  security_group_id = aws_security_group.sg_ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "sg_ec2_accept_443" {
  security_group_id = aws_security_group.sg_ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# wget, aptで必要そうなのでとりあえず全て許可
resource "aws_vpc_security_group_egress_rule" "sg_ec2_accept_0" {
  security_group_id = aws_security_group.sg_ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
