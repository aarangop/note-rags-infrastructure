# modules/sqs/main.tf

# Main SQS queue for file events
resource "aws_sqs_queue" "file_events_queue" {
  name                      = "${var.project_name}-${var.environment}-file-events"
  delay_seconds             = 0
  max_message_size          = 262144  # 256 KB
  message_retention_seconds = 1209600 # 14 days
  receive_wait_time_seconds = 20      # Long polling

  # Dead letter queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.file_events_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "file_events_dlq" {
  name                      = "${var.project_name}-${var.environment}-file-events-dlq"
  message_retention_seconds = 1209600 # 14 days
}
