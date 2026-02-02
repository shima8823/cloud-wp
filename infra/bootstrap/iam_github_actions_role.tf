# ------------------------------------------------------------------------------
# GitHub Actions CI/CD 専用ロール
# ------------------------------------------------------------------------------
# 現在のワークフロー (terraform plan のみ) に必要な最小権限:
# - AWS リソースの読み取り (plan用)
# - S3 State バケットへのアクセス (state読み取り + ロックファイル操作)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name        = "GitHubActionsRole"
  description = "Role for GitHub Actions CI/CD pipelines (read-only for terraform plan)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:shima8823/cloud-wp:pull_request"
          }
          StringLike = {
            "token.actions.githubusercontent.com:job_workflow_ref" = "shima8823/cloud-wp/.github/workflows/terraform.yml@*"
          }
        }
      }
    ]
  })

  max_session_duration = 3600
}

# ------------------------------------------------------------------------------
# 権限1: AWS リソース読み取り (terraform plan 用)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "github_actions_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ------------------------------------------------------------------------------
# 権限2: S3 State バケットへの書き込み (ロックファイル操作用)
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "github_actions_state_access" {
  name        = "GitHubActionsStateAccess"
  description = "Allows terraform state lock operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStateLockOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.terraform_state.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_state_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_state_access.arn
}
