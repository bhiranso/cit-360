# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-92d212f5"
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
  subnet_id = "${aws_subnet.public_subnet_a.id}"

  depends_on = ["aws_internet_gateway.gw"]

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

/* resource "aws_route" "private_route" {
  vpc_id = "${var.vpc_id}"
  route_table_id  = "${aws_route_table.private_routing_table.id}"
  destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
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
		cidr_blocks = ["0.0.0.0/0"]
	}
  	egress {
     	 	from_port = 0
     		to_port = 0
     	 	protocol = "-1"
      	 	cidr_blocks = ["0.0.0.0/0"]
  	}
	vpc_id = "${var.vpc_id}"
}

# DB security group
resource "aws_security_group" "default" {
    name = "rds_sg"
    description = "CIT Family"
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
      Name = "allow_all"
    }
}


/* Instances Security group */
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }
  ingress {
       from_port = -1
       to_port = -1
       protocol = "icmp"
       cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
         from_port = -1
         to_port = -1
         protocol = "icmp"
         cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
	vpc_id = "${var.vpc_id}"
}

# Security Group for ELB
resource "aws_security_group" "elb" {
	name = "elb"
	description = "Allow access from anywhere to an instance on port 80 (HTTP)"
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Subnet group
resource "aws_db_subnet_group" "db-1" {
    name = "main"
    description = "CIT Family"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]

    tags {
        Name = "My DB subnet group"
    }
}

# Relations Database Service (RDS) instance
resource "aws_db_instance" "rds-1" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  identifier           = "databay"
  instance_class       = "db.t2.micro"
  multi_az             = false
  storage_type         = "gp2"
# name                 = "mariadb"
  username             = "${var.username}"
  password             = "${var.password}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.db-1.id}"
# parameter_group_name = "default.mysql5.6"
  tags {
    Name = "MariaDB instance"
  }
}

# Elastic Load balancer
resource "aws_elb" "bar" {
  name = "CITFamilyLB"

  subnets = ["${aws_subnet.public_subnet_b.id}" , "${aws_subnet.public_subnet_c.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }

  health_check {
   healthy_threshold = 2
   unhealthy_threshold = 2
   timeout = 5
   target = "HTTP:80/"
   interval = 30
 }

  instances = ["${aws_instance.webserver_b.id}" , "${aws_instance.webserver_c.id}"]
  cross_zone_load_balancing = true
  #idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 60

  tags {
    Name = "CITFamilyLB"
  }

}

# webserver instance
resource "aws_instance" "webserver_b" {
    ami = "ami-5ec1673e"

    subnet_id = "${aws_subnet.private_subnet_b.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.allow_all.id}"]
    tags {
        Name = "webserver-b"
        Service = "curriculum"
    }
}

# webserver instance
resource "aws_instance" "webserver_c" {
    ami = "ami-5ec1673e"

    subnet_id = "${aws_subnet.private_subnet_c.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.allow_all.id}"]
    tags {
        Name = "webserver-c"
        Service = "curriculum"
    }
}
