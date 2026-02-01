# Bootstrap Infrastructure

このディレクトリは、Terraform による IaC（Infrastructure as Code）運用の「基盤」を構築します。  
**一度だけ実行**し、以降の全てのインフラ管理の土台となる重要なリソースを作成します。

詳細なセットアップ手順は [`docs/AWS_SETUP.md`](../../docs/AWS_SETUP.md) を参照してください。

---

## 作成されるリソース

### 1. Terraform State 管理用 S3 バケット (`storage.tf`)

**リソース**:
- `aws_s3_bucket.terraform_state` - Terraform の状態ファイル保管用バケット
- `aws_s3_bucket_versioning.state` - バージョニング有効化
- `aws_s3_bucket_lifecycle_configuration.state_lifecycle` - 古いバージョンの自動削除（30日後）

**目的**:  
Terraform の状態ファイル（tfstate）を安全に保管し、チーム間で共有可能にします。バージョニングにより、誤った変更からの復旧が可能です。

**特徴**:
- **バージョニング**: 過去の状態を保持し、ロールバック可能
- **ライフサイクル管理**: 30日以上前の古いバージョンを自動削除してストレージコストを削減

---

### 2. IAM ロール: TerraformAdminRole (`iam.tf`)

**リソース**:
- `aws_iam_role.terraform_admin` - 全権限を持つ管理者ロール
- `aws_iam_role_policy_attachment.admin_access` - AdministratorAccess ポリシーをアタッチ
- `aws_iam_user_policy.allow_assume_terraform_admin_role` - 実行中の IAM ユーザーに AssumeRole 権限を付与（条件付き）

**目的**:  
緊急時の復旧作業や、初期セットアップ時に使用する全権限ロールです。

**特徴**:
- **全権限**: AdministratorAccess により、AWS 上の全てのリソースを操作可能
- **信頼ポリシー**: アカウント内の全ての IAM エンティティ（`:root`）が引き受け可能
- **自動権限付与**: Terraform 実行中の IAM ユーザーに対して、自動的に AssumeRole 権限を付与（`count` によるリソース条件作成）

---

### 3. IAM ロール: TerraformDevRole（ガードレール付き）(`iam_dev_role.tf`)

**リソース**:
- `aws_iam_role.terraform_dev` - 開発用ロール
- `aws_iam_role_policy_attachment.dev_admin_access` - AdministratorAccess ポリシーをアタッチ
- `aws_iam_policy.dev_guardrail` - ガードレールポリシー（Deny Policy）
- `aws_iam_role_policy_attachment.dev_guardrail` - ガードレールポリシーをアタッチ

**目的**:  
日常的なインフラ開発作業に使用するロールです。AdministratorAccess を持ちながらも、重大な事故を防ぐための「ガードレール」が設定されています。

**ガードレールの内容**:

#### 1. ステートバケットの保護
- **バケット削除の禁止**: `s3:DeleteBucket`
- **ステートファイル削除の禁止**: `s3:DeleteObject`, `s3:DeleteObjectVersion`（tflock ファイルは除外）

#### 2. IAM ユーザー操作の禁止
- **ユーザー作成・削除**: `iam:CreateUser`, `iam:DeleteUser`
- **アクセスキー発行・削除**: `iam:CreateAccessKey`, `iam:DeleteAccessKey`

#### 3. ロール改変の禁止（脱獄防止）
- **対象**: `TerraformAdminRole` と `TerraformDevRole` 自身
- **禁止操作**: ポリシーのアタッチ/デタッチ、信頼関係の変更、ロールの削除

#### 4. ガードレールポリシー自体の保護
- **禁止操作**: ポリシーの削除、編集、バージョン変更

**重要**: これらの制限は **Explicit Deny（明示的な拒否）** として定義されており、たとえ AdministratorAccess を持っていても回避できません。

---

## セキュリティ上の注意

1. **ローカルバックエンド**: Bootstrap ディレクトリのみローカルに状態ファイルを保存します。このファイルは Git にコミットしないでください（`.gitignore` で除外済み）。

2. **ガードレール**: `TerraformDevRole` のガードレールは、うっかりミスによる重大な事故を防ぎますが、完全なセキュリティを保証するものではありません。重要な操作の前には必ず確認してください。
