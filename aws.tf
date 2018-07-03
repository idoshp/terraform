#aws.tf

variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AMI" {}

provider "aws" {
access_key = "${var.AWS_ACCESS_KEY}"
secret_key = "${var.AWS_SECRET_KEY}"
region = "us-east-1"
}

resource "aws_instance" "web_server" {
ami = "${var.AMI}"
instance_type = "t2.micro"
key_name = "docker"
count = 2
user_data = <<-EOF
	     #!bin/bash
	     sudo yum install httpd -y
             sudo echo "Welcome to my site!" > /var/www/html/index.html
             sudo yum update -y
             sudo service httpd start
             EOF
tags {
Name = "terraform instance"
}

}
resource "aws_security_group" "sgweb" {
  name = "launch-wizard-3"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
}

# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-east-1b","us-east-1a","us-east-1c","us-east-1d","us-east-1e","us-east-1f"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/index.html"
    interval            = 30
  }

  instances                   = ["${aws_instance.web_server.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "foobar-terraform-elb"
  }

}
output "ip" {
  value = "http://${aws_elb.bar.dns_name}"
}




