resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository for the API service"
  value       = aws_ecr_repository.api.repository_url
}