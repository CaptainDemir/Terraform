provider "aws" {
  region = "us-east-1"
}

# Data source to fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# EC2 Instances
resource "aws_instance" "ec2_instance" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  tags = {
    "Name" = count.index == 0 ? "Terraform First Instance" : "Terraform Second Instance"
  }

  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  provisioner "local-exec" {
    command = <<-EOF
      echo "${aws_instance.ec2_instance[0].public_ip}" >> public.txt
      echo "${aws_instance.ec2_instance[0].private_ip}" >> private.txt
    EOF
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    echo 'By CaptainDemir' > /var/www/html/index.html
    EOF
}

# Security Group
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Output Public IPs
output "public_ips" {
  value = aws_instance.ec2_instance[*].public_ip
}
