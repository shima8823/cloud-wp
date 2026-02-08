resource "aws_s3_bucket" "ssm_artifacts" {
  tags = {
    Name = "ansible-ssm-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_artifacts" {
  bucket = aws_s3_bucket.ssm_artifacts.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}
