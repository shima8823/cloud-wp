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

app-app:
	@terraform -chdir=app apply

des-app:
	@terraform -chdir=app destroy -auto-approve

re-app:
	@terraform -chdir=app destroy -auto-approve
	@terraform -chdir=app apply -auto-approve
