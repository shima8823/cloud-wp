variable "availability_zone" {
  description = "Availability Zone for the public subnet."
  type        = string
  default     = "ap-northeast-1a"
}

variable "aws_region" {
  description = "AWS region used by this stack."
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_name" {
  description = "EC2 Name tag value."
  type        = string
  default     = "wordpress"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "public_ingress_cidr_ipv4" {
  description = "IPv4 CIDR allowed for inbound HTTP/HTTPS."
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_route_cidr_ipv4" {
  description = "Destination IPv4 CIDR for the public default route."
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}
