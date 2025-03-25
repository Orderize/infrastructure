resource "aws_vpc" "vpc_orderize" {
	cidr_block 				= "10.0.0.0/24"
	enable_dns_support 		= true
	enable_dns_hostnames 	= true
	
	tags = {
		Name = "vpc_orderize"
	}
}

resource "aws_subnet" "public_subnet" {
	vpc_id 					= aws_vpc.vpc_orderize.id
	cidr_block 				= "10.0.0.0/25"
	availability_zone 		= "us-east-1a"
	map_public_ip_on_launch = true
	
	tags = {
		Name = "public_subnet"
	}
}

resource "aws_subnet" "private_subnet" {
	vpc_id 				= aws_vpc.vpc_orderize.id
	cidr_block 			= "10.0.0.128/25"
	availability_zone 	= "us-east-1a"

	tags = {
		Name = "private-subnet"
	}
}

resource "aws_internet_gateway" "igw_orderize" {
	vpc_id = aws_vpc.vpc_orderize.id

	tags = {
		Name = "igw_orderize"
	}
}

resource "aws_eip" "nat_eip" {
	domain = "vpc"
}

resource "aws_eip" "public_eip" {
	domain = "vpc"
}

resource "aws_nat_gateway" "nat_orderize" {
	allocation_id 	= aws_eip.nat_eip.id
	subnet_id 		= aws_subnet.public_subnet.id

	tags = {
		Name = "nat_orderize"
	}
}

resource "aws_route_table" "public_route_table" {
	vpc_id = aws_vpc.vpc_orderize.id
	
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw_orderize.id
	}

	tags = {
		Name = "public_route_table"
	}
}

resource "aws_route_table_association" "public_route_table_association" {
	subnet_id		 = aws_subnet.public_subnet.id
	route_table_id 	= aws_route_table.public_route_table.id

	
}

resource "aws_route_table" "private_route_table" {
	vpc_id = aws_vpc.vpc_orderize.id

	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.nat_orderize.id
	}

	tags = {
		Name = "private_route_table"
	} 
}

resource "aws_route_table_association" "private_route_table_association" {
	subnet_id = aws_subnet.private_subnet.id
	route_table_id = aws_route_table.private_route_table.id

	
}

resource "aws_security_group" "firewall" {
	vpc_id 	= aws_vpc.vpc_orderize.id
	name 	= "firewall"
	
	ingress {
		from_port 	= 0
		to_port 	= 0
		protocol 	= "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port 	= -1
		to_port 	= -1
		protocol 	= "icmp"
	}

	ingress {
		from_port 		= 8080
		to_port 		= 8080
		protocol 		= "tcp"
		cidr_blocks 	= ["10.0.0.0/25"]
	}

	ingress {
		from_port 		= 22
		to_port 		= 22
		protocol 		= "tcp"
		cidr_blocks 	= ["0.0.0.0/0"]
	}

	egress {
		from_port	 	= 0
		to_port 		= 0
		protocol 		= "-1"
		cidr_blocks 	= ["0.0.0.0/0"]
	}

	tags = {
		Name = "firewall"
	}
}

resource "aws_instance" "public_ec2" {
	ami 						= "ami-04b4f1a9cf54c11d0"
	instance_type 				= "t2.medium"
	subnet_id 					= aws_subnet.public_subnet.id
	associate_public_ip_address = true
	vpc_security_group_ids 		= [aws_security_group.firewall.id]
	key_name 					= "private keys"

	tags = {
		Name = "public_ec2"
	}
}

resource "aws_instance" "private_ec2" {
	ami 					= "ami-04b4f1a9cf54c11d0"
	instance_type 			= "t2.medium"
	subnet_id 				= aws_subnet.private_subnet.id
	vpc_security_group_ids 	= [aws_security_group.firewall.id]
	key_name 				= "private keys"

	tags = {
		Name = "private_ec2"
	}
}

resource "aws_eip_association" "public_eip_ec2" {
	instance_id 	= aws_instance.public_ec2.id
	allocation_id 	= aws_eip.public_eip.id

	
}

resource "aws_route53_zone" "domain_orderize" {
	name = "orderize.com"

	tags = {
		Name = "domain_orderize"
	}
}

resource "aws_route53_record" "ec2_dns" {
	zone_id = aws_route53_zone.domain_orderize.zone_id
	name 	= "orderize.com"
	type 	= "A"
	ttl 	= 300
	records = [aws_eip.public_eip.public_ip]
}

