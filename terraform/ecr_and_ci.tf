# 1. Look up the existing GitHub OIDC provider in your account
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. Look up the existing ECR repository
data "aws_ecr_repository" "api" {
  name = "anycompany-api"
}

# 3. Create the IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_ecr" {
  name = "${var.project_name}-github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # REPLACE WITH YOUR ACTUAL GITHUB USERNAME AND REPO (e.g. "yourname/Anycompany-cloud-modernization:*")
            "token.actions.githubusercontent.com:sub" = "repo:kmoldenhauer/anycompany-cloud-modernization:*"
          }
        }
      }
    ]
  })
}

# 4. Permissions: Allow pushing container layers to the anycompany-api repo
resource "aws_iam_policy" "github_ecr_push" {
  name        = "${var.project_name}-github-ecr-push-policy"
  description = "Allows GitHub Actions to push images to anycompany-api"

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
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = data.aws_ecr_repository.api.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr.arn
}