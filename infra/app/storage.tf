resource "aws_s3_bucket" "ssm_artifacts" {
  # Ansibleの実行が失敗するとバケットにファイルが残ってしまうので削除可能にする
  force_destroy = true

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
