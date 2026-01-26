# ------------------------------------------------------------------------------
# 1. ゲスト用ロール (制限付き管理者)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "terraform_dev" {
  name = "TerraformDevRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
}

# 基本権限: AdministratorAccessを与える
resource "aws_iam_role_policy_attachment" "dev_admin_access" {
  role       = aws_iam_role.terraform_dev.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ガードレールポリシー: 危険な操作と権限昇格を禁止
resource "aws_iam_policy" "dev_guardrail" {
  name        = "TerraformDevGuardrailPolicy"
  description = "Prevents destruction of critical resources and privilege escalation"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Backend S3 バケット削除の禁止
      {
        Sid      = "DenyStateBucketDelete"
        Effect   = "Deny"
        Action   = ["s3:DeleteBucket"]
        Resource = [aws_s3_bucket.terraform_state.arn]
      },
      # 2. ステートファイル自体の削除を禁止（ロックファイル *.tflock は除く）
      {
        Sid    = "ProtectStateObjects"
        Effect = "Deny"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = ["${aws_s3_bucket.terraform_state.arn}/*"]
        Condition = {
          StringNotLike = {
            "aws:ResourceArn" = ["${aws_s3_bucket.terraform_state.arn}/*.tflock"]
          }
        }
      },
      # 2. IAM Userなどの作成・削除禁止
      {
        Sid    = "DenyIAMUserOperations"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey"
        ]
        Resource = "*"
      },
      # 3. ガードレール外し(脱獄)の禁止
      # このRoleとAdminRoleに対してポリシーを外したり、信頼関係を変えたりすることを禁止
      {
        Sid    = "PreventRoleModification"
        Effect = "Deny"
        Action = [
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole"
        ]
        Resource = [
          aws_iam_role.terraform_admin.arn,
          aws_iam_role.terraform_dev.arn
        ]
      },
      # 4. このガードレールポリシー自体を削除・編集することを禁止
      {
        Sid    = "ProtectGuardrailPolicy"
        Effect = "Deny"
        Action = [
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/TerraformDevGuardrailPolicy"
      }
    ]
  })
}

# ガードレールポリシーをDevロールにアタッチ
resource "aws_iam_role_policy_attachment" "dev_guardrail" {
  role       = aws_iam_role.terraform_dev.name
  policy_arn = aws_iam_policy.dev_guardrail.arn
}
