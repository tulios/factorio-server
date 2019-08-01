provider "aws" {
  version    = "~> 2.0"
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  availability_zone       = "${var.aws_availability_zone}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "instance" {
  name   = "sg_instance"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27015
    to_port     = 27015
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

resource "aws_iam_role" "game_server_iam_role" {
  name = "game_server_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "game_server_instance_profile" {
  name = "game_server_instance_profile"
  role = "game_server_iam_role"
}

resource "aws_iam_role_policy" "game_server_iam_role_policy" {
  name = "game_server_iam_role_policy"
  role = "${aws_iam_role.game_server_iam_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${var.aws_bucket_name}",
        "arn:aws:s3:::${var.aws_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_instance" "game_server" {
  connection {
    host        = self.public_ip
    user        = "centos"
    private_key = file("${path.module}/private-factorio.pem")
  }

  instance_type          = "${var.aws_instance_type}"
  ami                    = "${lookup(var.aws_amis, var.aws_region)}"
  availability_zone      = "${var.aws_availability_zone}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  subnet_id            = "${aws_subnet.default.id}"
  iam_instance_profile = "${aws_iam_instance_profile.game_server_instance_profile.id}"

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "./bin/run.sh"
    destination = "/tmp/run.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/run.sh",
      "/tmp/run.sh",
    ]
  }
}

resource "aws_route53_record" "sthlm" {
  zone_id = "${var.aws_hosted_zone_id}"
  name    = "${var.aws_host_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.game_server.public_ip}"]
}
