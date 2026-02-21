output "public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.wordpress.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.wordpress.id
}

output "ansible_ssm_bucket_name" {
  description = "S3 bucket used by Ansible aws_ssm connection plugin."
  value       = aws_s3_bucket.ssm_artifacts.bucket
}
