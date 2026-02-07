data "aws_ami" "ubuntu_2004" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "wordpress" {
  ami                  = data.aws_ami.ubuntu_2004.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
  instance_type        = var.instance_type

  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  tags = {
    Name = var.instance_name
  }
}
