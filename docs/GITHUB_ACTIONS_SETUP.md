## GitHub Actions CI/CD セットアップ

このドキュメントでは、GitHub Actions から AWS へ OIDC 認証を使用して安全に接続するための設定手順を説明します。

### 構成概要

```
GitHub Actions
  │
  │ OIDC Token (短期トークン)
  ▼
AWS IAM OIDC Provider
  │
  │ sts:AssumeRoleWithWebIdentity
  ▼
GitHubActionsRole (読み取り専用)
  ├── ReadOnlyAccess
  └── GitHubActionsStateAccess (S3 ロックファイル操作)
```

従来の方式（IAM ユーザーのアクセスキーを GitHub Secrets に保存）と比較して、OIDC 認証には以下のメリットがあります：

- **長期認証情報が不要**: アクセスキーの漏洩リスクを排除
- **自動ローテーション**: トークンは短期間で自動失効
- **細かいアクセス制御**: リポジトリ・ブランチ単位で制限可能

---

### 1. 前提条件

以下のリソースが Terraform Bootstrap で作成済みであること：

| リソース | ファイル | 説明 |
|----------|----------|------|
| `aws_iam_openid_connect_provider.github_actions` | `github_oidc.tf` | GitHub Actions 用 OIDC プロバイダー |
| `aws_iam_role.github_actions` | `iam_github_actions_role.tf` | GitHub Actions 専用 IAM ロール |
| `aws_iam_policy.github_actions_state_access` | `iam_github_actions_role.tf` | S3 ロックファイル操作ポリシー |

---

### 2. Terraform Bootstrap の適用

OIDC プロバイダーと IAM ロールを作成します：

```bash
cd infra
make init-bootstrap
make apply-bootstrap
```

適用後、以下の出力を確認します：

```bash
terraform -chdir=bootstrap output
```

出力例：
```
github_actions_role_arn = "arn:aws:iam::123456789012:role/GitHubActionsRole"
state_bucket_name = "your-terraform-state-bucket"
terraform_dev_role_arn = "arn:aws:iam::123456789012:role/TerraformDevRole"
```

---

### 3. GitHub Secrets の設定

GitHub リポジトリの **Settings > Secrets and variables > Actions** で以下のシークレットを設定します：

| シークレット名 | 値 | 説明 |
|----------------|-----|------|
| `AWS_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRole` | GitHub Actions が引き受ける IAM ロールの ARN |
| `TF_STATE_BUCKET` | `<your-terraform-state-bucket>` | Terraform State を保存する S3 バケット名 |

> **取得方法**: 上記の `terraform output` コマンドで表示された値を使用してください。

---

### 4. ワークフローの動作

`.github/workflows/terraform.yml` で定義されたワークフローは、以下のように動作します：

#### トリガー条件
- `master` ブランチへの Pull Request
- `**.tf` ファイルまたはワークフロー自体の変更時

#### 必要な権限（permissions）
```yaml
permissions:
  id-token: write      # OIDC トークンの発行に必要
  contents: read       # リポジトリの読み取り
  pull-requests: write # PR へのコメント投稿
```

#### 実行ステップ
1. **Configure AWS Credentials**: OIDC 認証で AWS に接続
2. **Terraform Format Check**: コードフォーマットの検証
3. **Terraform Init**: S3 バックエンドで初期化
4. **Terraform Validate**: 構文検証
5. **Terraform Plan**: 変更計画を生成し、PR にコメント

---

### 5. IAM ロールの権限

`GitHubActionsRole` には最小権限の原則に従い、以下の権限のみ付与されています：

#### 読み取り権限
- **ReadOnlyAccess** (AWS 管理ポリシー): すべての AWS リソースの読み取り

#### 書き込み権限（限定的）
- **GitHubActionsStateAccess** (カスタムポリシー):
  ```json
  {
    "Effect": "Allow",
    "Action": ["s3:PutObject", "s3:DeleteObject"],
    "Resource": ["arn:aws:s3:::<bucket>/*.tflock"]
  }
  ```
  - Terraform のロックファイル（`*.tflock`）の作成・削除のみ許可
  - State ファイル自体の変更は不可

---

### 6. セキュリティ設計

#### 信頼ポリシーの制限

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:shima8823/cloud-wp:pull_request"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:job_workflow_ref": "shima8823/cloud-wp/.github/workflows/terraform.yml@*"
    }
  }
}
```

- **aud (Audience)**: `sts.amazonaws.com` のみ許可
- **sub (Subject)**: `pull_request` イベントのみ許可（push や workflow_dispatch を拒否）
- **job_workflow_ref**: `terraform.yml` ワークフローからのみ許可（任意のブランチ）
  - ワークフロー名を変更した場合は更新が必要です

#### 目的に合わせた変更例（必要な場合のみ）

用途に応じて、以下のように条件を変更できます：

```hcl
# 特定のブランチのワークフローのみ許可
"token.actions.githubusercontent.com:job_workflow_ref" = "shima8823/cloud-wp/.github/workflows/terraform.yml@refs/heads/master"

# push イベントも許可する場合（sub を StringLike に変更）
"token.actions.githubusercontent.com:sub" = "repo:shima8823/cloud-wp:*"

# 特定の Environment のみ許可
"token.actions.githubusercontent.com:sub" = "repo:shima8823/cloud-wp:environment:production"
```

#### セッション時間の制限

```hcl
max_session_duration = 3600  # 1時間
```

デフォルトの 12 時間から 1 時間に短縮し、万が一のトークン漏洩時の影響を最小化しています。

---

### 7. 関連ファイル

| ファイル | 説明 |
|----------|------|
| `infra/bootstrap/github_oidc.tf` | OIDC プロバイダーの定義 |
| `infra/bootstrap/iam_github_actions_role.tf` | GitHub Actions 用 IAM ロール |
| `infra/bootstrap/outputs.tf` | ロール ARN などの出力定義 |
| `.github/workflows/terraform.yml` | CI/CD ワークフロー定義 |

---

### 参考リンク

- [GitHub Docs: Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS: Creating OpenID Connect (OIDC) identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
