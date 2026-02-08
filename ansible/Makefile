.PHONY: deploy

TERRAFORM_APP_DIR ?= ../infra/app

deploy:
	@BUCKET=$$(terraform -chdir=$(TERRAFORM_APP_DIR) output -raw ansible_ssm_bucket_name); \
	if [ -z "$$BUCKET" ]; then \
		echo "Error: Could not get ansible_ssm_bucket_name from Terraform output."; \
		exit 1; \
	fi; \
	ansible-playbook main.yml -e ansible_aws_ssm_bucket_name="$$BUCKET"
