SHELL := /bin/bash

AZURE_TF_DIR := infrastructure/azure
AWS_TF_DIR := infrastructure/aws
TF_PLAN := tfplan.out
PORT ?= 8000
AZURE_STORAGE_ACCOUNT ?= $(shell terraform -chdir=$(AZURE_TF_DIR) output -raw storage_account_name 2>/dev/null)
AWS_PROFILE ?= personal
AWS_BUCKET ?= $(shell terraform -chdir=$(AWS_TF_DIR) output -raw bucket_name 2>/dev/null)
AWS_DISTRIBUTION_ID ?= $(shell terraform -chdir=$(AWS_TF_DIR) output -raw cloudfront_distribution_id 2>/dev/null)

PUBLIC_FILES := index.html 404.html styles.css app.js health.json robots.txt sitemap.xml

.DEFAULT_GOAL := help

.PHONY: help check-tools check-terraform check-az check-aws check-python azure-tf-init azure-tf-fmt azure-tf-validate azure-tf-plan azure-tf-show azure-tf-apply azure-tf-output azure-tf-destroy azure-deploy aws-tf-init aws-tf-fmt aws-tf-validate aws-tf-plan aws-tf-show aws-tf-apply aws-tf-output aws-tf-destroy aws-deploy run clean

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-terraform:
	@command -v terraform >/dev/null || { echo "terraform is required"; exit 1; }

check-az:
	@command -v az >/dev/null || { echo "Azure CLI is required"; exit 1; }

check-aws:
	@command -v aws >/dev/null || { echo "AWS CLI is required"; exit 1; }

check-python:
	@command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

check-tools: check-terraform check-az check-aws check-python ## Verify Terraform, Azure CLI, AWS CLI, and Python are installed

# Azure (Storage static website + Front Door)

azure-tf-init: check-terraform ## Initialize the Azure Terraform providers and local state
	terraform -chdir=$(AZURE_TF_DIR) init

azure-tf-fmt: check-terraform ## Format the Azure Terraform configuration
	terraform -chdir=$(AZURE_TF_DIR) fmt -recursive

azure-tf-validate: azure-tf-init ## Validate the Azure Terraform configuration
	terraform -chdir=$(AZURE_TF_DIR) validate

azure-tf-plan: check-terraform ## Initialize, format, validate, and save an Azure Terraform plan
	terraform -chdir=$(AZURE_TF_DIR) init
	terraform -chdir=$(AZURE_TF_DIR) fmt -recursive
	terraform -chdir=$(AZURE_TF_DIR) validate
	terraform -chdir=$(AZURE_TF_DIR) plan -out=$(TF_PLAN)

azure-tf-show: check-terraform ## Show the saved Azure Terraform plan for review
	@test -f "$(AZURE_TF_DIR)/$(TF_PLAN)" || { echo "Missing $(AZURE_TF_DIR)/$(TF_PLAN). Run 'make azure-tf-plan' first."; exit 1; }
	terraform -chdir=$(AZURE_TF_DIR) show $(TF_PLAN)

azure-tf-apply: check-terraform ## Apply the saved Azure tfplan.out exactly as reviewed
	@test -f "$(AZURE_TF_DIR)/$(TF_PLAN)" || { echo "Missing $(AZURE_TF_DIR)/$(TF_PLAN). Run 'make azure-tf-plan' first."; exit 1; }
	terraform -chdir=$(AZURE_TF_DIR) apply $(TF_PLAN)

azure-tf-output: check-terraform ## Show the Azure Terraform outputs
	terraform -chdir=$(AZURE_TF_DIR) output

azure-tf-destroy: check-terraform ## Destroy the Terraform-managed Azure resources
	terraform -chdir=$(AZURE_TF_DIR) destroy

azure-deploy: check-terraform check-az ## Upload the current landing page to the existing Azure Storage account
	@test -n "$(AZURE_STORAGE_ACCOUNT)" || { echo "Storage account not found. Apply Terraform first or run 'make azure-deploy AZURE_STORAGE_ACCOUNT=<name>'."; exit 1; }
	az storage blob service-properties update \
		--account-name "$(AZURE_STORAGE_ACCOUNT)" \
		--static-website true \
		--index-document index.html \
		--404-document 404.html \
		--auth-mode login
	@for file in $(PUBLIC_FILES); do \
		az storage blob upload \
			--account-name "$(AZURE_STORAGE_ACCOUNT)" \
			--container-name '$$web' \
			--name "$$file" \
			--file "$$file" \
			--overwrite true \
			--auth-mode login || exit 1; \
	done
	@find assets -type f ! -name '.DS_Store' -print0 | while IFS= read -r -d '' file; do \
		blob_name="$${file#assets/}"; \
		az storage blob upload \
			--account-name "$(AZURE_STORAGE_ACCOUNT)" \
			--container-name '$$web' \
			--name "assets/$$blob_name" \
			--file "$$file" \
			--overwrite true \
			--auth-mode login || exit 1; \
	done
	@echo "Deployed to $$(terraform -chdir=$(AZURE_TF_DIR) output -raw website_url 2>/dev/null || true)"

# AWS (S3 + CloudFront)

aws-tf-init: check-terraform ## Initialize the AWS Terraform providers and local state
	terraform -chdir=$(AWS_TF_DIR) init

aws-tf-fmt: check-terraform ## Format the AWS Terraform configuration
	terraform -chdir=$(AWS_TF_DIR) fmt -recursive

aws-tf-validate: aws-tf-init ## Validate the AWS Terraform configuration
	terraform -chdir=$(AWS_TF_DIR) validate

aws-tf-plan: check-terraform ## Initialize, format, validate, and save an AWS Terraform plan
	terraform -chdir=$(AWS_TF_DIR) init
	terraform -chdir=$(AWS_TF_DIR) fmt -recursive
	terraform -chdir=$(AWS_TF_DIR) validate
	terraform -chdir=$(AWS_TF_DIR) plan -out=$(TF_PLAN)

aws-tf-show: check-terraform ## Show the saved AWS Terraform plan for review
	@test -f "$(AWS_TF_DIR)/$(TF_PLAN)" || { echo "Missing $(AWS_TF_DIR)/$(TF_PLAN). Run 'make aws-tf-plan' first."; exit 1; }
	terraform -chdir=$(AWS_TF_DIR) show $(TF_PLAN)

aws-tf-apply: check-terraform ## Apply the saved AWS tfplan.out exactly as reviewed
	@test -f "$(AWS_TF_DIR)/$(TF_PLAN)" || { echo "Missing $(AWS_TF_DIR)/$(TF_PLAN). Run 'make aws-tf-plan' first."; exit 1; }
	terraform -chdir=$(AWS_TF_DIR) apply $(TF_PLAN)

aws-tf-output: check-terraform ## Show the AWS Terraform outputs
	terraform -chdir=$(AWS_TF_DIR) output

aws-tf-destroy: check-terraform ## Destroy the Terraform-managed AWS resources
	terraform -chdir=$(AWS_TF_DIR) destroy

aws-deploy: check-terraform check-aws ## Sync the landing page to S3 and invalidate CloudFront
	@test -n "$(AWS_BUCKET)" -a -n "$(AWS_DISTRIBUTION_ID)" || { echo "AWS stack not found. Run 'make aws-tf-apply' first."; exit 1; }
	@for file in $(PUBLIC_FILES); do \
		aws s3 cp "$$file" "s3://$(AWS_BUCKET)/$$file" --profile "$(AWS_PROFILE)" --only-show-errors || exit 1; \
	done
	aws s3 sync assets "s3://$(AWS_BUCKET)/assets" --exclude '*.DS_Store' --profile "$(AWS_PROFILE)" --only-show-errors
	aws cloudfront create-invalidation --distribution-id "$(AWS_DISTRIBUTION_ID)" --paths '/*' --profile "$(AWS_PROFILE)" --query 'Invalidation.Id' --output text
	@echo "Deployed to $$(terraform -chdir=$(AWS_TF_DIR) output -raw cloudfront_url 2>/dev/null || true)"

run: check-python ## Run the landing page locally (PORT=8000 by default)
	@echo "Serving http://localhost:$(PORT)"
	python3 -m http.server $(PORT)

clean: ## Remove the saved Terraform plans
	rm -f "$(AZURE_TF_DIR)/$(TF_PLAN)" "$(AWS_TF_DIR)/$(TF_PLAN)"
