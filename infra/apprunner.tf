# 1. دور الصلاحيات (IAM Role) للسماح لـ App Runner بسحب الصورة من ECR
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "apprunner-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# 2. دور الصلاحيات (Instance Role) للسماح لتطبيق FastAPI بالتعامل مع SQS و DynamoDB
resource "aws_iam_role" "apprunner_instance_role" {
  name = "apprunner-fastapi-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "fastapi_aws_access" {
  name = "fastapi-sqs-dynamodb-policy"
  role = aws_iam_role.apprunner_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. خدمة AWS App Runner لتشغيل حاوية FastAPI وتمرير متغيرات البيئة بدقة
resource "aws_apprunner_service" "fastapi_service" {
  service_name = "fastapi-backend-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"
        runtime_environment_variables = {
          AWS_REGION          = "ap-southeast-2"
          SQS_QUEUE_ARN       = module.messages_queue.main_arn      # رابط الطابور الأساسي للرسائل
          SQS_DLQ_ARN         = module.messages_queue.dlq_arn       # رابط الطابور التالف (DLQ)
          USERS_TABLE_NAME    = module.users_table.table_name       # جدول المستخدمين
          MESSAGES_TABLE_NAME = module.messages_table.table_name    # جدول الرسائل
        }
      }
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  depends_on = [aws_iam_role_policy_attachment.apprunner_ecr_policy]
}

# 4. طباعة الرابط العام للتطبيق بعد اكتمال الإنشاء
output "fastapi_live_url" {
  value       = "https://${aws_apprunner_service.fastapi_service.service_url}"
  description = "Live HTTPS URL for your FastAPI application"
}
