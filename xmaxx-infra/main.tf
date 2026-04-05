terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

locals {
  k3s_cluster_name = "xmaxx-k3s"
  k3s_version      = "v1.32.3+k3s1"
}

data "aws_key_pair" "xmaxx" {
  key_name = "xmaxx"
}

resource "aws_vpc" "project" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-vpc"
  }
}

resource "aws_internet_gateway" "project" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "project-igw"
  }
}

resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "project-subnet-public1-us-east-2a"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "project-subnet-public2-us-east-2b"
  }
}

resource "aws_subnet" "misc_2b" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.32.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_2a" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.128.0/20"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "project-subnet-private1-us-east-2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.144.0/20"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "project-subnet-private2-us-east-2b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "project-rtb-public"
  }
}

resource "aws_route_table" "private_2a" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "project-rtb-private1-us-east-2a"
  }
}

resource "aws_route_table" "private_2b" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "project-rtb-private2-us-east-2b"
  }
}

data "aws_route_table" "main" {
  vpc_id = aws_vpc.project.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project.id
}

resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_2b" {
  subnet_id      = aws_subnet.private_2b.id
  route_table_id = aws_route_table.private_2b.id
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.project.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_2a.id,
    aws_route_table.private_2b.id,
  ]
  private_dns_enabled = false
  ip_address_type     = "ipv4"

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
      }
    ]
  })

  tags = {
    Name = "project-vpce-s3"
  }
}

resource "aws_security_group" "launch_wizard_1" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2026-03-30T00:14:20.696Z"
  vpc_id      = aws_vpc.project.id

  ingress {
    description = ""
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = ""
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [aws_vpc.project.cidr_block]
  }

  ingress {
    description = "Kubelet metrics and exec"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.project.cidr_block]
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.project.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "xmaxx" {
  ami                         = "ami-07062e2a343acc423"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.private_2a.id
  vpc_security_group_ids      = [aws_security_group.launch_wizard_1.id]
  key_name                    = data.aws_key_pair.xmaxx.key_name
  iam_instance_profile        = aws_iam_instance_profile.k3s_node_ecr_pull.name
  associate_public_ip_address = true
  monitoring                  = false
  user_data_replace_on_change = false
  user_data                   = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y curl

    TOKEN=$(curl -X PUT -fsSL "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=$(curl -fsSL -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/public-ipv4)

    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${local.k3s_version}' sh -s - server \
      --write-kubeconfig-mode 644 \
      --tls-san $PUBLIC_IP \
      --node-name ${local.k3s_cluster_name}-server

    until [ -f /etc/rancher/k3s/k3s.yaml ]; do
      sleep 2
    done

    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/kubeconfig.yaml
    chown ubuntu:ubuntu /home/ubuntu/kubeconfig.yaml
    sed -i "s/127.0.0.1/$PUBLIC_IP/" /home/ubuntu/kubeconfig.yaml
  EOF

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 8
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "xmaxx"
  }
}

resource "aws_lb" "k3s_api" {
  name               = "xmaxx-k3s-api"
  internal           = false
  load_balancer_type = "network"
  subnets = [
    aws_subnet.public_2a.id,
    aws_subnet.public_2b.id,
  ]
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "xmaxx-k3s-api"
  }
}

resource "aws_lb_target_group" "k3s_api" {
  name        = "xmaxx-k3s-api"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.project.id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "6443"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "xmaxx-k3s-api"
  }
}

resource "aws_lb_target_group_attachment" "k3s_api_server" {
  target_group_arn = aws_lb_target_group.k3s_api.arn
  target_id        = aws_instance.xmaxx.id
  port             = 6443
}

resource "aws_lb_listener" "k3s_api" {
  load_balancer_arn = aws_lb.k3s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_api.arn
  }
}

output "server_public_ip" {
  value = aws_instance.xmaxx.public_ip
}

output "server_ssh" {
  value = "ssh -i ~/.ssh/xmaxx ubuntu@${aws_instance.xmaxx.public_ip}"
}

output "kubeconfig_copy" {
  value = "scp -i ~/.ssh/xmaxx ubuntu@${aws_instance.xmaxx.public_ip}:/home/ubuntu/kubeconfig.yaml ./kubeconfig.yaml"
}

output "k3s_join_token_command" {
  value = "ssh -i ~/.ssh/xmaxx ubuntu@${aws_instance.xmaxx.public_ip} sudo cat /var/lib/rancher/k3s/server/node-token"
}

output "k3s_api_lb_dns_name" {
  value = aws_lb.k3s_api.dns_name
}

output "k3s_api_lb_zone_id" {
  value = aws_lb.k3s_api.zone_id
}
