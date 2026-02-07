output "state_bucket_name" {
  description = "Terraform state bucket name."
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_dev_role_arn" {
  description = "ARN of TerraformDevRole."
  value       = aws_iam_role.terraform_dev.arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions CI/CD用ロールARN（GitHub Secretsに設定）"
  value       = aws_iam_role.github_actions.arn
}
