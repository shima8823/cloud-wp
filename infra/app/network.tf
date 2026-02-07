resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.availability_zone
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name        = "fw-ec2"
  description = "Security group for the WordPress EC2 instance."
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_http" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_https" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# パッケージダウンロード用
resource "aws_vpc_security_group_egress_rule" "egress_http" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# HTTPS通信用（apt/yum、WordPress更新など）
resource "aws_vpc_security_group_egress_rule" "egress_https" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# VPC ResolverへのDNSクエリ用（UDP/TCP両方）
# VPC ResolverのIPアドレスはVPC CIDRのプラス2（例: vpc_cidr(10.0.0.0) + 2 = 10.0.0.2）
resource "aws_vpc_security_group_egress_rule" "egress_dns_udp" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "${cidrhost(var.vpc_cidr, 2)}/32"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}

resource "aws_vpc_security_group_egress_rule" "egress_dns_tcp" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "${cidrhost(var.vpc_cidr, 2)}/32"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
}
