# modules/s3/main.tf

# S3 bucket for storing Obsidian vault files
resource "aws_s3_bucket" "obsidian_vault" {
  bucket = var.bucket_name
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "obsidian_vault_versioning" {
  bucket = aws_s3_bucket.obsidian_vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "obsidian_vault_pab" {
  bucket = aws_s3_bucket.obsidian_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "obsidian_vault_encryption" {
  bucket = aws_s3_bucket.obsidian_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
