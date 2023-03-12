provider "aws" {
    region = "us-east-1"

  
}

variable "vpc_cidr" {
  
}
variable "subnet_cidr" {

}
variable "avability_zone" {
  
}
variable "env_prefix" {
  
}
variable "instance_type" {
  
}
variable "public_key_location" {
  
}

resource "aws_vpc" "T-101" {
  cidr_block = var.vpc_cidr
  tags = { Name= "${var.env_prefix}-T101"}
}

resource "aws_subnet" "T-101-Subnet-1a" {
  vpc_id     = aws_vpc.T-101.id
  cidr_block = var.subnet_cidr
  availability_zone = var.avability_zone

  tags = {
    Name = "${var.env_prefix}-T101-Subnet-1a"
  }
}
resource "aws_internet_gateway" "T101-gw" {
  vpc_id = aws_vpc.T-101.id

  tags = {
    Name = "${var.env_prefix}-T101-IG"
  }
}
resource "aws_route_table" "T-101-RT" {
     vpc_id = aws_vpc.T-101.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.T101-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.T101-gw.id
  }

  tags = {
    Name = "${var.env_prefix}-T-101-RT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.T-101-Subnet-1a.id
  route_table_id = aws_route_table.T-101-RT.id
}

resource "aws_security_group" "T-101-SG" {
  name        = "T-101-SG"
  description = "Allow Port 22 and 8080  inbound traffic"
  vpc_id      = aws_vpc.T-101.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description      = "Port:8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_prefix}-T-101-SG"
  }
}

data "aws_ami" "laset-amazon-linux-image" {
  most_recent = true
owners = ["amazon"]
 filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
 filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }


}
resource "aws_instance" "T-101-web-server" {
  ami           = data.aws_ami.laset-amazon-linux-image.id
  instance_type = var.instance_type
  key_name = aws_key_pair.T-101-Key.key_name
  subnet_id = aws_subnet.T-101-Subnet-1a.id
  vpc_security_group_ids = [ aws_security_group.T-101-SG.id ]
  availability_zone = var.avability_zone
  associate_public_ip_address = true
  
  user_data = file("user_data.sh")
  tags = {
    Name = "${var.env_prefix}-T-101-Web-Server"
  }
}
resource "aws_key_pair" "T-101-Key" {
  key_name   = "server_key"
  public_key = file(var.public_key_location)

}


output "aws_ami_id" {
  value = data.aws_ami.laset-amazon-linux-image.id
}

output "ec2_public_ip" {
    value = aws_instance.T-101-web-server.public_ip
}