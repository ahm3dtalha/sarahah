
# الدور: يسمح لخدمة Lambda بتولّي الصلاحيات
resource "aws_iam_role" "lambda_role" {
  name = "lambda-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# صلاحية قراءة الطابور وكتابة السجلات
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-sqs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect   = "Allow"
            Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
            Resource = "*"
        },
        {
            Effect   = "Allow"
            Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
            Resource = module.messages_queue.main_arn
        },
        {
            Effect   = "Allow"
            Action   = ["dynamodb:PutItem"]
            Resource = module.messages_table.table_arn
        }
    ]
  })
}
