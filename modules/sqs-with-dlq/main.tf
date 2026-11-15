resource "aws_sqs_queue" "dlq" {
    name = "${var.name}-dlq"
}
resource "aws_sqs_queue" "main" {
    name = var.name
    visibility_timeout_seconds = var.visibility_timeout
    delay_seconds                = var.delay_seconds   
    max_message_size             = var.max_size                    #الحجم الاقصي للرسالة الواحدة
    message_retention_seconds    = var.retention_seconds           # مدة الاحتفاظ بالرسالة 
   
    redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.dlq.arn
        maxReceiveCount =var.max_receive_count
    })
}