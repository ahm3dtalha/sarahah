data "archive_file" "lambda_zip" {
  type = "zip"
  source_dir = "${path.module}/../application/lambda"
  output_path =   "${path.module}/lambda.zip"
  excludes = [ "lambda_function.py" ]
}

resource "aws_lambda_function" "processor" {
  function_name    = "message-processor"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      MESSAGES_TABLE = module.messages_table.table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn        = module.messages_queue.main_arn
  function_name           = aws_lambda_function.processor.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}