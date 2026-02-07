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

resource "local_file" "ansible_ssm_group_vars" {
  # Intentional side effect: publish Terraform output for Ansible runtime.
  content  = <<EOT
# SSM接続用S3バケット名（Terraformで作成）
ansible_aws_ssm_bucket_name: ${aws_s3_bucket.ssm_artifacts.bucket}
EOT
  filename = "${path.module}/../../ansible/group_vars/all.yml"
}
