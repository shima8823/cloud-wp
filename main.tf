provider "aws" {
  region = "ap-northeast-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  # sshキーを指定
  # TODO: SessionManagerにする
  key_name      = aws_key_pair.myKeyPair.key_name

  vpc_security_group_ids = [aws_security_group.sgEc2.id]
  subnet_id              = aws_subnet.mySubnetPub1a.id

  tags = {
    Name = var.instance_name
  }
}

####################
# VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
####################
resource "aws_vpc" "myVpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc_ec2_wordpress"
  }
}

####################
# Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
####################
resource "aws_subnet" "mySubnetPub1a" {
  vpc_id                  = aws_vpc.myVpc.id
  availability_zone       = "ap-northeast-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "pub-subnet-1a"
  }
}

####################
# Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
####################
resource "aws_route_table" "myPubRoute1a" {
  vpc_id = aws_vpc.myVpc.id

  tags = {
    Name = "pub-route-table"
  }
}

####################
# IGW
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway
####################
resource "aws_internet_gateway" "myIgw" {
  vpc_id = aws_vpc.myVpc.id

  tags = {
    Name = "igw"
  }
}

####################
# Route Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
####################
resource "aws_route" "myPubRouteRule1a" {
  route_table_id         = aws_route_table.myPubRoute1a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myIgw.id
  depends_on             = [aws_route_table.myPubRoute1a]
}

####################
# Route Rule Associcate Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
####################
resource "aws_route_table_association" "myPubRouteRuleAssociatSubnet1a" {
  subnet_id      = aws_subnet.mySubnetPub1a.id
  route_table_id = aws_route_table.myPubRoute1a.id
}

####################
# Security Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
####################
resource "aws_security_group" "sgEc2" {
  name        = "fw-ec2"
  description = "SG_EC2"
  vpc_id      = aws_vpc.myVpc.id
}

# 自分のIPアドレスを動的に取得
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}


# SSHキーを作成
# TODO: SessionManagerにする
resource "tls_private_key" "this" {
  algorithm = "ED25519"
}

resource "local_file" "private" {
  filename        = "id_ed25519"
  content         = tls_private_key.this.private_key_openssh
  file_permission = "0600"
}

####################
# aws_key_pair
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
####################
resource "aws_key_pair" "myKeyPair" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_vpc_security_group_ingress_rule" "sgEc2Accept80" {
  security_group_id = aws_security_group.sgEc2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "sgEc2Accept22" {
  security_group_id = aws_security_group.sgEc2.id

  # TODO: SessionManagerにする
  cidr_ipv4   = "${chomp(data.http.my_ip.response_body)}/32"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "sgEc2Accept443" {
  security_group_id = aws_security_group.sgEc2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# wget, aptで必要そうなのでとりあえず全て許可
resource "aws_vpc_security_group_egress_rule" "sgEc2Accept0" {
  security_group_id = aws_security_group.sgEc2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
  enable_dns_hostnames = true
}
