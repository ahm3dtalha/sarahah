resource "aws_ecr_repository" "app_repo" {
  name                 = "fastapi-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# إخراج رابط المستودع لنستحقه لاحقاً في الـ Workflow
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "The URL of the ECR repository"
}
