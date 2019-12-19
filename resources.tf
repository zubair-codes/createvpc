#finds the most recent ami
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["amazon"]
}


#create the VPC
resource "aws_vpc" "zubair-research-vpc" {
  cidr_block = "${var.vpcCIDRBlock}"

  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    #assign tag for VPC
    Name = "zubair-research-vpc"
  }
}

#create internet gateway
resource "aws_internet_gateway" "zubair-vpc-gw"{
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  tags  ={
    Name = "zubair-vpc-gw"
  }
}

#create pubic route table
resource "aws_route_table" "zubair-vpc-rt-public" {
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  tags = {
    Name = "zubair-vpc-rt-public"
  }
}

#create private route table
resource "aws_route_table" "zubair-vpc-rt-private" {
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  tags = {
    Name = "zubair-vpc-rt-private"
  }
}

//#create internet(route) access for public(bastion)
//resource "aws_route" "zubair-public-VPC-route" {
//  route_table_id = "${aws_route_table.zubair-vpc-rt-public.id}"
//  destination_cidr_block = "${var.destinationCIDRBlock}"
//  gateway_id = "${aws_internet_gateway.zubair-vpc-gw.id}"
//}
//
//#create internet(route) access to private
//resource "aws_route" "zubair-private-VPC-route" {
//  route_table_id = "${aws_route_table.zubair-vpc-rt-private.id}"
//  destination_cidr_block = "${var.destinationCIDRBlock}"
//  gateway_id = "${aws_internet_gateway.zubair-vpc-gw.id}"
//}

#create public subnet
resource "aws_subnet" "zubair-public-subnet"{
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  cidr_block = "${var.publicSubnetCIDRBlock}"
  tags = {
    Name = "zubair-public-subnet"
  }
}

#create private subnet
resource "aws_subnet" "zubair-private-subnet"{
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  cidr_block = "${var.privateSubnetCIDRBlock}"
  tags = {
    Name = "zubair-private-subnet"
  }
}

#route table association between public subnet and public route table
resource "aws_route_table_association" "zubair-public-rt-association" {
  route_table_id = "${aws_route_table.zubair-vpc-rt-public.id}"
  subnet_id = "${aws_subnet.zubair-public-subnet.id}"
}

#route table association between private subnet and private route table
resource "aws_route_table_association" "zubair-private-rt-association" {
  route_table_id = "${aws_route_table.zubair-vpc-rt-private.id}"
  subnet_id = "${aws_subnet.zubair-private-subnet.id}"
}

#create aws network acl and tie them to the subnets as well as ingress and egress
resource "aws_network_acl" "zubair-network-acl"{
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  subnet_ids = ["${aws_subnet.zubair-public-subnet.id}", "${aws_subnet.zubair-private-subnet.id}"]

  #allow ingress port 22 (ssh access)
  ingress {
    action = "allow"
    from_port = 22
    protocol = "tcp"
    rule_no = 100         #first rule
    to_port = 22
    cidr_block = "${var.destinationCIDRBlock}"
  }

  #allow egress port 22 (ssh access)
  egress {
    action = "allow"
    from_port = 22
    protocol = "tcp"
    rule_no = 100
    to_port = 22
    cidr_block = "${var.destinationCIDRBlock}"
  }


  tags = {
    Name = "zubair-network-acl"
  }
}

#create public (bastion) security group with ingress and egress
resource "aws_security_group" "zubair-public-sg" {
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  name = "zubair-public-sg"
  description = "Security group for public(bastion) subnet in zubair-research-vpc"
  tags = {
    Name = "zubair-public-sg"
  }
}

#allow ingress for public sg
resource "aws_security_group_rule" "zubair-sg-rule-public-ingress"{
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zubair-public-sg.id}"
  cidr_blocks              = ["${var.destinationCIDRBlock}"]
}

#allow egress for public sg
resource "aws_security_group_rule" "zubair-sg-rule-public-egress"{
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zubair-public-sg.id}"
  source_security_group_id = "${aws_security_group.zubair-private-sg.id}"
}

#create private security group with ingress pointing to bastion
resource "aws_security_group" "zubair-private-sg" {
  vpc_id = "${aws_vpc.zubair-research-vpc.id}"
  name = "zubair-private-sg"
  description = "Security group for private subnet in zubair-research-vpc"


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }

  tags = {
    Name = "zubair-private-sg"
  }
}

#allow ingress for private sg
resource "aws_security_group_rule" "zubair-sg-rule-private-ingress"{
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zubair-private-sg.id}"
  source_security_group_id = "${aws_security_group.zubair-public-sg.id}"
}


#bastion ec2 instance
resource "aws_instance" "zubair-bastion" {
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.zubair-public-sg.id}"]
  subnet_id = "${aws_subnet.zubair-public-subnet.id}"
  tags = {
    Name = "zubair-bastion"
  }
}

#private instance
resource "aws_instance" "zubair-private-instance" {              #variable name of terraform resource
  ami = data.aws_ami.amazon-linux-2.id                           #latest ami is used as ami for EC2 instance
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.zubair-private-sg.id}"]
  subnet_id = "${aws_subnet.zubair-public-subnet.id}"             #was the one not added
  tags = {
    Name = "zubair-private-instance"                             #name of EC2 instance created
  }
}





















