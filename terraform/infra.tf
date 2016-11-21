
#Set the provider region
provider "aws" {
  region = "us-west-2"
}


#The internet gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

#Elastic resource for the NAT
resource "aws_eip" "nat" {
  vpc = true
}

#The NAT Gateway for the private subnets
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"

}

#Create a public subnets in the three AWS us-west-2 regions
#Uses /24 CIDR
resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.1.0/24"
  availability_zone = "us-west-2b"

  tags {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.2.0/24"
  availability_zone = "us-west-2c"

  tags {
    Name = "public_c"
  }
}

#Create private subnets in the three AWS us-west-2 regions
#Uses /22 CIDR
resource "aws_subnet" "private_subnet_a"{
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.4.0/22"
  availability_zone = "us-west-2a"

  tags {
    Name = "private_a"
  }
}

resource "aws_subnet" "private_subnet_b"{
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.8.0/22"
  availability_zone = "us-west-2b"

  tags {
    Name = "private_b"
  }
}

resource "aws_subnet" "private_subnet_c"{
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.12.0/22"
  availability_zone = "us-west-2c"

  tags {
    Name = "private_c"
  }
}

#Create a public routing table for public subnets
#to connect to the internet gateway
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#Create a private routing table for private subnets to
# connect to the NAT gateway
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}

#Associating each subnet to a routing table
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

#The security group to allow SSH and only allow IP's from a certain
#CIDR block.
resource "aws_security_group" "ssh_public" {
  name = "cit360-example"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    #The IP block that is allowed to connect
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow SSH"
  }
}

#Security group for the web servers
resource "aws_security_group" "web_server_sg" {
  name = "web-server"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "web_sever_security_group"
  }
}

#ELB security group
resource "aws_security_group" "elb_sg" {
  name = "elb-sg"
  vpc_id = "${var.vpc_id}"

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

resource "aws_instance" "bastion" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  associate_public_ip_address = true
  key_name = "cit360"
  vpc_security_group_ids = ["${aws_security_group.ssh_public.id}"]

  tags {
    Name = "bastion"
  }
}

#The security group for the RDS, allows access from within the VPC
resource "aws_security_group" "rds_sg" {
  name = "rds-sg"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
}

#The subnet group for the DB, accociated with 2 private subnets
resource "aws_db_subnet_group" "cit360_db_group" {
  name = "main"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]

  tags {
    Name = "cit360 db_subnet_group"
  }
}

#The db instance
resource "aws_db_instance" "cit360_db" {
  identifier = "db-cit360"
  allocated_storage = 5
  engine = "mariadb"
  engine_version = "10.0.24"
  instance_class = "db.t2.micro"
  multi_az = false
  name = "db_1"
  username = "bhiranso"
  password = "${var.password}"
  db_subnet_group_name = "${aws_db_subnet_group.cit360_db_group.id}"
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]

  tags {
    Name = "cit360_db"
  }
}

#Elastic load balancer for the webservers
resource "aws_elb" "cit360_elb" {
  name = "cit360-elb"
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.webserver-b.id}", "${aws_instance.webserver-c.id}"]
  connection_draining = true
  connection_draining_timeout = 60
  security_groups = ["${aws_security_group.elb_sg.id}"]

  tags {
    Name = "Load balancer"
  }
}

resource "aws_instance" "webserver-b" {
  ami = "ami-d2c924b2"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  associate_public_ip_address = false
  key_name = "cit360"
  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]

  tags {
    Name = "webserver-b"
    Service = "curriculum"
  }
}

resource "aws_instance" "webserver-c" {
  ami = "ami-d2c924b2"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  associate_public_ip_address = false
  key_name = "cit360"
  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]

  tags {
    Name = "webserver-c"
    Service = "curriculum"
  }
}
