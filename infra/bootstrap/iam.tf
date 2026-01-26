data "aws_caller_identity" "current" {}

resource "aws_iam_role" "terraform_admin" {
  name = "TerraformAdminRole"

  lifecycle {
    prevent_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Project   = "CloudStudy"
    ManagedBy = "Terraform"
    Owner     = "shima"
  }
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy" "allow_assume_terraform_admin_role" {
  # 現在の実行者が IAM User の場合のみリソースを作成する
  count = length(regexall(":user/", data.aws_caller_identity.current.arn)) > 0 ? 1 : 0
  name  = "AllowAssumeTerraformAdminRole"
  user  = split("/", data.aws_caller_identity.current.arn)[1]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.terraform_admin.arn
      }
    ]
  })
}
