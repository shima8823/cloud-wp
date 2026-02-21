resource "aws_s3_bucket" "ssm_artifacts" {
  # Ansible の一時ファイルのみを格納する想定のバケット。
  # Ansible の実行が失敗するとバケットにファイルが残ってしまうため、destroy 時にバケットごと削除できるようにする。
  # 本番環境では使用しないこと（force_destroy = true によりバケット内オブジェクトが無条件で削除されるため）。
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
