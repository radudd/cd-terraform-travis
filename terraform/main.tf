provider "aws" {
  region = "eu-west-1"
}

variable "cidr_blocks" { type = "list" }
variable "region" {}
variable "public_key_path" {}
variable "remote_user" {}
variable "dokku_version" {}
variable "app_port" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu*16.04-amd64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "dokku_sg" {
  name = "dokku_sg"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.cidr_blocks}"
  }
  ingress {
    from_port = "${var.app_port}"
    to_port = "${var.app_port}"
    protocol = "tcp"
    cidr_blocks = "${var.cidr_blocks}"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "dokku_key" {
  key_name   = "dokku_key"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "dokku" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"

  key_name        = "${aws_key_pair.dokku_key.key_name}"

  security_groups = ["${aws_security_group.dokku_sg.name}"]

  tags {
    App = "Dokku"
  }

  user_data = <<-EOF
              #!/bin/bash
              # https://github.com/dokku/dokku/issues/501
              wget -O /etc/init/docker.conf https://raw.github.com/dotcloud/docker/master/contrib/init/upstart/docker.conf
              service docker restart
              # Install Dokku
              wget https://raw.githubusercontent.com/dokku/dokku/${var.dokku_version}/bootstrap.sh
              DOKKU_TAG=${var.dokku_version} bash bootstrap.sh
              # Configure Dokku
              dokku ssh-keys:add key01 /home/${var.remote_user}/.ssh/authorized_keys &> /var/log/dokku_config.log
              EOF
}

output "public_dns" {
  value = "${aws_instance.dokku.public_dns}"
}
