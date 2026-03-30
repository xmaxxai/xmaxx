terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "key_name" {
  type    = string
  default = "xmaxx"
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "ami_id" {
  type    = string
  default = "ami-07062e2a343acc423"
}

variable "k3s_version" {
  type    = string
  default = "v1.32.3+k3s1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "app_lb_subnet_ids" {
  type = list(string)
}

variable "k3s_url" {
  type = string
}

variable "k3s_token" {
  type      = string
  sensitive = true
}

resource "aws_security_group" "k3s_workers" {
  name        = "k3s-workers"
  description = "K3s worker node traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Kubelet metrics and exec"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTP app traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS app traffic"
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.k3s_workers.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data_replace_on_change = false
  user_data                   = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y curl

    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' K3S_URL='${var.k3s_url}' K3S_TOKEN='${var.k3s_token}' sh -s - agent
  EOF

  tags = {
    Name = "xmaxx-k3s-worker-${count.index + 1}"
  }
}

resource "aws_lb" "app" {
  name                             = "xmaxx-app"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = var.app_lb_subnet_ids
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "xmaxx-app"
  }
}

resource "aws_lb_target_group" "app_http" {
  name        = "xmaxx-app-http"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "80"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "xmaxx-app-http"
  }
}

resource "aws_lb_target_group" "app_https" {
  name        = "xmaxx-app-https"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "443"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "xmaxx-app-https"
  }
}

resource "aws_lb_target_group_attachment" "app_http" {
  count            = length(aws_instance.worker)
  target_group_arn = aws_lb_target_group.app_http.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_https" {
  count            = length(aws_instance.worker)
  target_group_arn = aws_lb_target_group.app_https.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 443
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_http.arn
  }
}

resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_https.arn
  }
}

output "worker_public_ips" {
  value = aws_instance.worker[*].public_ip
}

output "worker_instance_ids" {
  value = aws_instance.worker[*].id
}

output "app_lb_dns_name" {
  value = aws_lb.app.dns_name
}

output "app_lb_zone_id" {
  value = aws_lb.app.zone_id
}
