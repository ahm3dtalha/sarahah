variable "ssh_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"] # غيّرها إلى عنوانك: ["x.x.x.x/32"]
  description = "العناوين المسموح لها بالمنفذ 22"
}

data "aws_region" "current" {}

# سر توقيع جلسات الدخول (JWT): يُولَّد مرة واحدة ويُحفظ في الـ state
resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

# 1. Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "fastapi-ec2-sg"
  description = "Allow inbound traffic for FastAPI and SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr
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

# 2. دور IAM للسيرفر
resource "aws_iam_role" "ec2_execution_role" {
  name = "ec2-fastapi-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# قراءة الصور من ECR
resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# الدخول إلى السيرفر من الـ Console (Session Manager) دون SSH
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# صلاحيات التطبيق: فقط ما يحتاجه ومحدد بمواردنا
resource "aws_iam_role_policy" "ec2_app_access" {
  name = "ec2-sqs-dynamodb-policy"
  role = aws_iam_role.ec2_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
        Resource = module.messages_queue.main_arn
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = [
          module.users_table.table_arn,
          "${module.users_table.table_arn}/index/*",
          module.messages_table.table_arn,
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-fastapi-instance-profile"
  role = aws_iam_role.ec2_execution_role.name
}

# 3. أحدث صورة Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 4. السيرفر
resource "aws_instance" "fastapi_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # أي تعديل على user_data يستبدل السيرفر ليُنفَّذ السكربت من جديد
  user_data_replace_on_change = true

  # يسمح للحاوية بقراءة بيانات الدور من السيرفر
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/app-setup.log) 2>&1

    apt-get update -y
    apt-get install -y docker.io awscli
    systemctl enable --now docker

    REGION="${data.aws_region.current.name}"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

    # انتظر وصول الصورة إلى ECR (حتى 10 دقائق)
    for i in $(seq 1 30); do
      docker pull "$ECR_URL/fastapi-app:latest" && break
      echo "image not ready yet, retrying..."
      sleep 20
    done

    docker run -d --restart unless-stopped -p 80:8000 \
      -e AWS_REGION="$REGION" \
      -e USERS_TABLE="${module.users_table.table_name}" \
      -e MESSAGES_TABLE="${module.messages_table.table_name}" \
      -e QUEUE_NAME="sarahah-messages" \
      -e JWT_SECRET="${random_password.jwt_secret.result}" \
      "$ECR_URL/fastapi-app:latest"
  EOF

  tags = {
    Name = "FastAPI-EC2-Server"
  }
}

# 5. عنوان ثابت لا يتغير عند إعادة إنشاء السيرفر
resource "aws_eip" "fastapi" {
  instance = aws_instance.fastapi_server.id
  domain   = "vpc"
}

output "ec2_public_ip" {
  value       = aws_eip.fastapi.public_ip
  description = "Public IP address of the EC2 instance"
}