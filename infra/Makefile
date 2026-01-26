.PHONY: init-bootstrap plan-bootstrap apply-bootstrap init-app plan-app apply-app re-app

init-bootstrap:
	@terraform -chdir=bootstrap init

plan-bootstrap:
	@terraform -chdir=bootstrap plan

apply-bootstrap:
	@terraform -chdir=bootstrap apply

init-app:
	@echo "Initializing app with backend bucket from bootstrap..."
	@BUCKET=$$(terraform -chdir=bootstrap output -raw state_bucket_name); \
	if [ -z "$$BUCKET" ]; then \
		echo "Error: Could not get state_bucket_name from bootstrap."; \
		exit 1; \
	fi; \
	echo "Using bucket: $$BUCKET"; \
	terraform -chdir=app init \
		-backend-config="bucket=$$BUCKET"

plan-app:
	@terraform -chdir=app plan

apply-app:
	@terraform -chdir=app apply

destroy-app:
	@terraform -chdir=app destroy

re-app:
	@terraform -chdir=app destroy -auto-approve
	@terraform -chdir=app apply -auto-approve

# terraform開発者の一時的なaccess key, secret key, session tokenを取得
# --duration-seconds min 15m, max 1h
get-auth-dev:
	@ROLE_ARN=$$(terraform -chdir=bootstrap output -raw terraform_dev_role_arn); \
	creds=$$(aws sts assume-role \
		--role-arn $$ROLE_ARN \
		--role-session-name dev-session \
		--duration-seconds 3600 \
		--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
		--output text); \
	read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$$creds"; \
	echo "export AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID"; \
	echo "export AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY"; \
	echo "export AWS_SESSION_TOKEN=$$AWS_SESSION_TOKEN"

clear-auth:
	@echo "unset AWS_ACCESS_KEY_ID"; \
	echo "unset AWS_SECRET_ACCESS_KEY"; \
	echo "unset AWS_SESSION_TOKEN"

# bootstrap初期設定 ref: ../docs/AWS_SETUP.md
delete-iam-admin-inline-policy:
	@echo "aws iam detach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name <YOUR_IAM_USERNAME>"
