data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_repository = "xmaxxai/xmaxx"

  ecr_repositories = {
    home         = "xmaxx/home"
    home_backend = "xmaxx/home-backend"
  }
}

resource "aws_ecr_repository" "app" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 30 most recent tagged images"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = [
            "latest",
            "backend-latest",
            "sha-",
          ]
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the 10 most recent untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[length(data.tls_certificate.github_actions.certificates) - 1].sha1_fingerprint,
  ]
}

resource "aws_iam_role" "github_actions_ecr_push" {
  name = "xmaxx-github-actions-ecr-push"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_repository}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_ecr_push" {
  name = "xmaxx-github-actions-ecr-push"
  role = aws_iam_role.github_actions_ecr_push.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
        ]
        Resource = values(aws_ecr_repository.app)[*].arn
      }
    ]
  })
}

resource "aws_iam_role" "k3s_node_ecr_pull" {
  name = "xmaxx-k3s-node-ecr-pull"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "k3s_node_ecr_pull" {
  name = "xmaxx-k3s-node-ecr-pull"
  role = aws_iam_role.k3s_node_ecr_pull.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = values(aws_ecr_repository.app)[*].arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k3s_node_ecr_pull" {
  name = "xmaxx-k3s-node-ecr-pull"
  role = aws_iam_role.k3s_node_ecr_pull.name
}

output "github_actions_ecr_push_role_arn" {
  value = aws_iam_role.github_actions_ecr_push.arn
}

output "ecr_registry" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "home_ecr_repository_url" {
  value = aws_ecr_repository.app["home"].repository_url
}

output "home_backend_ecr_repository_url" {
  value = aws_ecr_repository.app["home_backend"].repository_url
}

output "k3s_node_instance_profile_name" {
  value = aws_iam_instance_profile.k3s_node_ecr_pull.name
}
