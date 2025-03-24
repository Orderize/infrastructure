provider "aws" {
    region  = "us-east-1"
    profile = "default"
}

resource "aws_vpc" "vpc_development" {
    cidr_block           = "10.0.0.0/30"
    enable_dns_support   = true
    enable_dns_hostnames = true
    
    tags = {
        Name = "vpc_development"
    } 
}

resource "aws_subnet" "public_subnet" {
    vpc_id            = aws_vpc.vpc_development.id 
    cidr_block        = "10.0.0.0/31"
    availability_zone = "us-east-1a"
    
    tags = {
        Name = "public_subnet"
    }
}

resource "aws_internet_gateway" "igw_development" {
    vpc_id = aws_vpc.vpc_development.id

    tags = {
        Name = "igw_development"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc_development.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_development.id
    }

    tags = {
        Name = "public_route_table"
    }
}

resource "aws_route_table_association" "development_route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_instance" "development_ec2" {
	ami = "ami-04b4f1a9cf54c11d0"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.public_subnet.id
	associate_public_ip_address = true
    key_name = "private keys"
	
	tags = {
		Name = "development_ec2"
	}
}