# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-4452a023"
}


provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "us-west-2"
}

#Create new default Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags {
      Name = "default_ig"
  }
}

#Create NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.lb.id}"
  subnet_id = "${aws_subnet.private_subnet_a.id}"

  #depends_on = ["aws_internet_gateway.gw"]

}

resource "aws_eip" "lb" {
  depends_on = ["aws_internet_gateway.gw"]
  vpc = true
}

#routing table for public subnets
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "main_routing_table"
  }
}

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

# public subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.1.0/24"
  availability_zone = "us-west-2a"

  tags {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.2.0/24"
  availability_zone = "us-west-2b"

  tags {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.3.0/24"
  availability_zone = "us-west-2c"

  tags {
    Name = "public_c"
  }
}

# Routing for private subnets
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
  tags {
    Name = "private_routing_table"
  }
}

/*resource "aws_route" "private_route" {
  vpc_id = "${var.vpc_id}"
  route_table_id  = "${aws_route_table.private_routing_table.id}"
	# destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.gw.id}"
}
*/
resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

# private subnets
resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.16.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.20.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.24.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}

# Bastion instance
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.bastion.id}"]
    tags {
        Name = "Bastion"
    }
}


# Security Group for Bastion instance
resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow access from your current public IP address to an instance on port 22 (SSH)"
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["172.31.0.0/16"]
	}

	vpc_id = "${var.vpc_id}"
}
