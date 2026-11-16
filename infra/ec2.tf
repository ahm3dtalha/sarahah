# 1. Security Group للسماح بالاتصال عبر SSH (التحكم) و Port 8000 (تطبيق FastAPI)
resource "aws_security_group" "ec2_sg" {
  name        = "fastapi-ec2-sg"
  description = "Allow inbound traffic for FastAPI and SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "FastAPI"
    from_port   = 8000
    to_port     = 8000
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

# 2. دور IAM لكي يقرأ سرفر EC2 الصورة من ECR ويتعامل مع SQS و DynamoDB
resource "aws_iam_role" "ec2_execution_role" {
  name = "ec2-fastapi-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ec2_app_access" {
  name = "ec2-sqs-dynamodb-policy"
  role = aws_iam_role.ec2_execution_role.id

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

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-fastapi-instance-profile"
  role = aws_iam_role.ec2_execution_role.name
}

# 3. جلب أحدث صورة لـ Ubuntu لنظام التشغيل
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# 4. إنشاء سرفر EC2 وتثبيت Docker وتشغيل الحاوية تلقائياً
resource "aws_instance" "fastapi_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro" # مناسب جداً للتعلم والتجارب (Free tier متوفر غالباً)
  security_groups      = [aws_security_group.ec2_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io awscli
              systemctl start docker
              systemctl enable docker

              # تسجيل الدخول إلى ECR وسحب الصورة وتشغيلها
              REGION="ap-southeast-2"
              ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
              ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

              aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

              # تشغيل حاوية التطبيق وتمرير متغيرات البيئة
              docker run -d -p 80:8000 \
                -e AWS_REGION="$REGION" \
                -e SQS_QUEUE_ARN="${module.messages_queue.main_arn}" \
                -e SQS_DLQ_ARN="${module.messages_queue.dlq_arn}" \
                -e USERS_TABLE_NAME="${module.users_table.table_name}" \
                -e MESSAGES_TABLE_NAME="${module.messages_table.table_name}" \
                "$ECR_URL/fastapi-app:latest"
              EOF

  tags = {
    Name = "FastAPI-EC2-Server"
  }
}

# 5. طباعة عنوان الـ IP العام للوصول للتطبيق
output "ec2_public_ip" {
  value       = aws_instance.fastapi_server.public_ip
  description = "Public IP address of the EC2 instance"
}
