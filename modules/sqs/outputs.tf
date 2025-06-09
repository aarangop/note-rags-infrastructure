# modules/sqs/outputs.tf
output "queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.file_events_queue.url
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.file_events_queue.arn
}

output "queue_name" {
  description = "Name of the SQS queue"
  value       = aws_sqs_queue.file_events_queue.name
}

output "dlq_url" {
  description = "URL of the Dead Letter Queue"
  value       = aws_sqs_queue.file_events_dlq.url
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = aws_sqs_queue.file_events_dlq.arn
}
