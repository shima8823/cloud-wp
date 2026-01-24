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
