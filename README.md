# Cloud-1 - WordPress 自動デプロイ on AWS

WordPress を AWS EC2 上に自動デプロイし、HTTPS 対応の本番相当環境を構築するプロジェクトです。  
Terraform による IaC（Infrastructure as Code）と Ansible による構成管理を組み合わせ、再現性の高いインフラ構築を実現しています。

## 🌟 特徴

- ✅ **完全自動化**: Terraform + Ansible によるワンコマンドデプロイ
- ✅ **HTTPS 対応**: Let's Encrypt による無料 SSL 証明書の自動取得・更新
- ✅ **動的 DNS**: Dynu DDNS による固定ドメイン名の利用
- ✅ **セキュアな権限管理**: STS AssumeRole による一時的な認証情報の使用
- ✅ **インフラコード化**: すべてのリソースが Git で管理可能

## 📋 前提条件

### 必須ツール
- [Terraform](https://www.terraform.io/) `~> 1.14.0`
- [Ansible](https://www.ansible.com/) `>= 2.17, < 2.18`
- [AWS CLI](https://aws.amazon.com/cli/)
- Python 3.x、pip

### AWS アカウント
- 初回セットアップについては [`docs/AWS_SETUP.md`](./docs/AWS_SETUP.md) を参照してください
- 無料枠内での構築を想定していますが、一部リソースで課金が発生する可能性があります

### 外部サービス
- [Dynu](https://www.dynu.com) アカウント（無料 DDNS サービス）

---

## 🚀 クイックスタート

> **初めての方**: AWS アカウントのセットアップがまだの場合は、先に [`docs/AWS_SETUP.md`](./docs/AWS_SETUP.md) を参照してください。

### 1. AWS 認証情報の準備

```bash
# TerraformDevRole を引き受け、一時的な認証情報を取得
eval $(make -C infra get-auth-dev)

# 確認
aws sts get-caller-identity
# Arn が "...assumed-role/TerraformDevRole/dev-session" となっていれば OK
```

### 2. 環境変数の設定

```bash
# Dynu DDNS 設定
export DYNU_HOSTNAME="your-domain.com"
export DYNU_PASSWORD="your-dynu-api-password"

# Let's Encrypt 設定
export LETSENCRYPT_EMAIL="your-email@example.com"

# 確認
env | grep -E "DYNU|LETSENCRYPT"
```

### 3. インフラのデプロイ

```bash
cd infra
make init-app
make plan-app
make apply-app
```

### 4. WordPress のデプロイ

```bash
cd ../ansible
ansible-playbook -i inventory/aws_ec2.yml main.yml
```

### 5. アクセス確認

ブラウザで `https://your-domain.com` にアクセスし、WordPress のセットアップ画面が表示されることを確認します。

---

## 📚 ドキュメント

| ドキュメント | 説明 |
|------------|------|
| [`docs/AWS_SETUP.md`](./docs/AWS_SETUP.md) | AWS アカウントの初期セットアップ手順（Root → IAM User → AssumeRole） |
| [`docs/architecture.drawio.svg`](./docs/architecture.drawio.svg) | インフラ構成図（VPC、EC2、セキュリティグループなど） |
| [`infra/bootstrap/README.md`](./infra/bootstrap/README.md) | Bootstrap インフラ（IAM ロール、S3 バケット）の詳細 |

---

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│ AWS Account                                         │
│                                                     │
│  ┌─────────────┐      ┌──────────────────────┐    │
│  │ IAM User    │─────▶│ TerraformDevRole     │    │
│  │ (初期設定)   │      │ (日常開発用)          │    │
│  └─────────────┘      │ + Guardrail Policy   │    │
│                       └──────────────────────┘    │
│                                                     │
│  ┌─────────────────────────────────────────────┐  │
│  │ S3 Bucket (Terraform State)                 │  │
│  │ - バージョニング有効                          │  │
│  │ - ライフサイクル管理                          │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│  ┌─────────────────────────────────────────────┐  │
│  │ EC2 Instance (WordPress)                     │  │
│  │  ├─ Docker Compose                           │  │
│  │  │   ├─ WordPress                            │  │
│  │  │   ├─ Nginx (Reverse Proxy)                │  │
│  │  │   └─ MariaDB                              │  │
│  │  └─ Let's Encrypt (SSL 証明書)               │  │
│  └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                    ▲
                    │ HTTPS
          ┌─────────┴─────────┐
          │ Dynu DDNS         │
          │ (動的DNS)          │
          └───────────────────┘
```

> **詳細な構成図**: より詳しいインフラ構成図は [`docs/architecture.drawio.svg`](./docs/architecture.drawio.svg) を参照してください。VPC、サブネット、セキュリティグループなどの詳細な構成が記載されています。

---

## 🛠️ 開発フロー

### 日常的な作業

```bash
cd infra
# 1. 認証情報の取得（有効期限 1時間）
eval $(make get-auth-dev)

# 2. インフラの変更
make plan-app
make apply-app

# 3. 認証情報のクリア（オプション）
eval $(make clear-auth)
```

### リソースの削除

```bash
cd infra
make destroy-app
```

---

## 🔒 セキュリティ

### ガードレール機能

`TerraformDevRole` には以下の保護機能が組み込まれています：

- ✅ **ステートバケット保護**: S3 バケットやステートファイルの削除を禁止
- ✅ **IAM ユーザー操作禁止**: IAM ユーザーの作成・削除、アクセスキー発行を禁止
- ✅ **脱獄防止**: ロール自身やガードレールポリシーの変更・削除を禁止

これらは **Explicit Deny（明示的な拒否）** として定義されており、AdministratorAccess を持っていても回避できません。

### 認証情報の管理

- ❌ **長期アクセスキーは使用しない**: PC にアクセスキーを保存せず、AssumeRole で一時的な認証情報を取得
- ⏰ **時間制限**: 認証情報は最大 1時間で自動失効
- 🔄 **ロール切り替え**: 必要に応じて Admin ロールと Dev ロールを使い分け

---

## 🐛 トラブルシューティング

### Terraform で削除操作が失敗する

> **問題**: `aws login` で取得した認証情報を使用していると、一部のリソース（特に IAM 関連）の削除が失敗する

**解決策**: `eval $(make -C infra get-auth-dev)` で STS AssumeRole の認証情報に切り替える

詳細: [GitHub Issue #45316](https://github.com/hashicorp/terraform-provider-aws/issues/45316)

### 認証情報の有効期限切れ

> **問題**: `ExpiredToken` エラーが発生する

**解決策**: 再度 `eval $(make -C infra get-auth-dev)` を実行

---

## 📦 プロジェクト構成

```
cloud-1/
├── README.md                    # このファイル
├── docs/                        # ドキュメント
│   └── AWS_SETUP.md            # AWS 初期セットアップ手順
├── infra/                       # Terraform (インフラ定義)
│   ├── Makefile                # よく使うコマンドのショートカット
│   ├── bootstrap/              # 基盤リソース（IAM, S3）
│   └── app/                    # アプリケーションリソース（EC2, VPC など）
├── ansible/                     # Ansible (構成管理)
│   ├── inventory/              # インベントリ（AWS 動的インベントリ）
│   ├── roles/                  # ロール（WordPress, Docker など）
│   └── main.yml                # メインプレイブック
└── app/                         # WordPress アプリケーション
    └── docker-compose.yml      # Docker Compose 設定
```

---

## 🤝 コントリビューション

Issue や Pull Request は大歓迎です。

---
