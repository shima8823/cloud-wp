####################
# S3 Bucket for Ansible SSM
####################
resource "aws_s3_bucket" "ansible_ssm" {
  tags = {
    Name = "ansible-ssm-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}

resource "local_file" "ansible_group_vars" {
  content  = <<EOT
# SSM接続用S3バケット名（Terraformで作成）
ansible_aws_ssm_bucket_name: ${aws_s3_bucket.ansible_ssm.bucket}
EOT
  filename = "${path.module}/../../ansible/group_vars/all.yml"
}
