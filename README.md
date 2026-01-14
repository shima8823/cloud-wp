# Cloud-1 - Inception自動デプロイ

InceptionプロジェクトをAWS EC2上に自動デプロイします。DynuでDDNSドメインを設定し、Let's EncryptでSSL証明書を自動取得します。

## 環境変数の設定

### AWS認証情報

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

> [!CAUTION]
> AWS認証情報は秘密情報です。Gitにコミットしないでください。

### Dynu DDNS設定

```bash
export DYNU_HOSTNAME="your-dynu-domain"
export DYNU_PASSWORD="your-dynu-password"
```

Dynuのドメインとパスワード（API認証用）を設定します。Dynuは https://www.dynu.com で利用できます。

### Let's Encrypt設定

```bash
export LETSENCRYPT_EMAIL="your-email@example.com"
```

証明書の有効期限通知に使用されます。

## セットアップ手順

### 1. 環境変数を設定

```bash
# AWS
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"

# Dynu DDNS
export DYNU_HOSTNAME="tanstaafl.gleeze.com"
export DYNU_PASSWORD="your-dynu-password"

# Let's Encrypt
export LETSENCRYPT_EMAIL="your-email@example.com"

# 確認
env | grep -E "AWS|DYNU|LETSENCRYPT"
```

### 2. Terraformでインフラを作成

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 3. Ansibleでアプリケーションをデプロイ

```bash
cd ../ansible
ansible-playbook -i inventry/aws_ec2.yml main.yml
```

### 4. アクセス確認

```bash
# HTTPSでアクセス
https://your-dynu-domain
```

## 必要なツール

### Python & Ansible

```bash
pip install "ansible-core>=2.17,<2.18" boto3 botocore
ansible-galaxy collection install amazon.aws
```

## リソースのクリーンアップ

```bash
cd infra
terraform destroy
```
