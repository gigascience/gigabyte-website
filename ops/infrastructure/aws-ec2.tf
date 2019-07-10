provider "aws" {
	access_key = "${var.aws_access_key}"
 	secret_key = "${var.aws_secret_key}"
	region     = "ap-southeast-1"
}

resource "aws_security_group" "landing_host" {
  name        = "landing_host"
  description = "Allow connection to landing host"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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


resource "aws_instance" "landing_host" {
  # Deploy Ubuntu 18.04 LTS
  ami = "ami-0b97def01ce4527ab"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.landing_host.id}"]
  key_name = "aws-ubuntu18_04-keys"
  tags = {
    Name = "ec2-as1-landing-gigabyte"
  }

  root_block_device = {
    delete_on_termination = "true"
  }
}

data "aws_eip" "landing_eip" {
  filter {
    name   = "tag:Name"
    values = ["eip-landing-gigabyte"]
  }
}

resource "aws_eip_association" "landing_eip" {
  instance_id   = "${aws_instance.landing_host.id}"
  allocation_id = "${data.aws_eip.landing_eip.id}"
}
