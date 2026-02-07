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

# 自動化を優先して Ansible 用の group_vars をここで生成している。
# 本来は Terraform の output を Ansible 側から参照する連携の方が副作用が少なく望ましい。
resource "local_file" "ansible_ssm_group_vars" {
  content  = <<EOT
# SSM接続用S3バケット名（Terraformで作成）
ansible_aws_ssm_bucket_name: ${aws_s3_bucket.ssm_artifacts.bucket}
EOT
  filename = "${path.module}/../../ansible/group_vars/all.yml"
}
