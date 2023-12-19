# Setting Block - Top level
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Resource Block
# Creation of VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

# Creation of Internet Gateway(igw)
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MY-IGW"
  }
}

# Creation of Subnet-Public(pub-sub)
resource "aws_subnet" "sub-pub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "PUB-SUB"
  }
}

# Creation of Subnet-Private(pvt-sub)
resource "aws_subnet" "sub-pvt" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "PVT-SUB"
  }
}

# create of RouteTable-Public(pub-rt)
resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "MYPUB-RT"
  }
}

# create of RouteTable-Private(pvt-rt)
resource "aws_route_table" "rt-pvt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "MYPVT-RT"
  }
}

# Association of (pub-sub) with (pub-rt)
resource "aws_route_table_association" "assopub-sub-rt" {
  subnet_id      = aws_subnet.sub-pub.id
  route_table_id = aws_route_table.rt-pub.id
}

# Association of (pvt-sub) with (pvt-rt)
resource "aws_route_table_association" "assopvt-sub-rt" {
  subnet_id      = aws_subnet.sub-pvt.id
  route_table_id = aws_route_table.rt-pvt.id
}

# creation of SecurityGroup-Public(pub-sg)
resource "aws_security_group" "secg-pub" {
  name        = "pub-secg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "MY-PUB-SECG"
  }
}

# creation of SecurityGroup-Private(pvt-sg)
resource "aws_security_group_rule" "secg-pvt" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.myvpc.cidr_block]
  security_group_id = aws_security_group.secg-pub.id
}

# Creation of Elastic IP(elip) with (pub-sub)
resource "aws_eip" "myel-ip" {
  domain   = "vpc"
}

# Creation of NAT Gateway(nat-gw)
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.myel-ip.id
  subnet_id     = aws_subnet.sub-pub.id

  tags = {
    Name = "MY-NAT"
  }
}

# Creation of Web Server(web-ser)
resource "aws_instance" "web" {
  ami           = "ami-074f77adfeee318d3"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.secg-pub.id]
  subnet_id = aws_subnet.sub-pub.id

  tags = {
    Name = "MY-WEB"
  }
}
# Creation of App Server(app-ser)
resource "aws_instance" "server2" {
  ami           = "ami-074f77adfeee318d3"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.secg-pvt.id]
  subnet_id = aws_subnet.sub-pvt.id

  tags = {
    Name = "MY-APP"
  }
}
