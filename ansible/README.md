# Ansible Setup Guide

このディレクトリは、`infra/app` で作成済みの EC2 に対して Ansible で構成管理を適用します。

## Prerequisites

- `infra/app` が `terraform apply` 済みであること
- AWS 認証情報が有効であること
- Python 3.10+ が使えること

推奨: ルートの `infra` で認証情報を取得

```bash
eval "$(make -C ../infra get-auth-dev)"
```

## Install

```bash
cd ansible
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml
```

## Required Environment Variables

```bash
export DYNU_HOSTNAME="example.com"
export DYNU_PASSWORD="your-dynu-password"
export LETSENCRYPT_EMAIL="you@example.com"
```

## Deploy

`ansible/Makefile` は Terraform output (`ansible_ssm_bucket_name`) を前提にしています。

```bash
cd ansible
make deploy
```

手動実行する場合:

```bash
BUCKET="$(terraform -chdir=../infra/app output -raw ansible_ssm_bucket_name)"
ansible-playbook main.yml -e ansible_aws_ssm_bucket_name="$BUCKET"
```

## Validation

```bash
ansible-playbook --syntax-check main.yml
ansible-lint main.yml
```

## Notes

- SSL は現在 `standalone` 方式です（`tasks/ssl.yml` 参照）。
- 更新時の停止を避ける `webroot` 化は TODO として管理しています。
- 詳細トラブルシュートは `ansible/TROUBLESHOOTING.md` を参照してください。

