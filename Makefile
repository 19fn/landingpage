SHELL := /bin/bash

TF_DIR := infrastructure/terraform
TF_PLAN := tfplan.out
PORT ?= 8000
STORAGE_ACCOUNT ?= $(shell terraform -chdir=$(TF_DIR) output -raw storage_account_name 2>/dev/null)

PUBLIC_FILES := index.html 404.html styles.css app.js

.DEFAULT_GOAL := help

.PHONY: help check-tools check-terraform check-az check-python tf-init tf-fmt tf-validate tf-plan tf-show tf-apply tf-output tf-destroy deploy run clean

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-terraform:
	@command -v terraform >/dev/null || { echo "terraform is required"; exit 1; }

check-az:
	@command -v az >/dev/null || { echo "Azure CLI is required"; exit 1; }

check-python:
	@command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

check-tools: check-terraform check-az check-python ## Verify Terraform, Azure CLI, and Python are installed

tf-init: check-terraform ## Initialize Terraform providers and local state
	terraform -chdir=$(TF_DIR) init

tf-fmt: check-terraform ## Format Terraform configuration
	terraform -chdir=$(TF_DIR) fmt -recursive

tf-validate: tf-init ## Validate Terraform configuration
	terraform -chdir=$(TF_DIR) validate

tf-plan: check-terraform ## Initialize, format, validate, and save a Terraform plan
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) fmt -recursive
	terraform -chdir=$(TF_DIR) validate
	terraform -chdir=$(TF_DIR) plan -out=$(TF_PLAN)

tf-show: check-terraform ## Show the saved Terraform plan for review
	@test -f "$(TF_DIR)/$(TF_PLAN)" || { echo "Missing $(TF_DIR)/$(TF_PLAN). Run 'make tf-plan' first."; exit 1; }
	terraform -chdir=$(TF_DIR) show $(TF_PLAN)

tf-apply: check-terraform ## Apply the saved tfplan.out exactly as reviewed
	@test -f "$(TF_DIR)/$(TF_PLAN)" || { echo "Missing $(TF_DIR)/$(TF_PLAN). Run 'make tf-plan' first."; exit 1; }
	terraform -chdir=$(TF_DIR) apply $(TF_PLAN)

tf-output: check-terraform ## Show Terraform outputs, including the website URL
	terraform -chdir=$(TF_DIR) output

tf-destroy: check-terraform ## Destroy the Terraform-managed Azure resources
	terraform -chdir=$(TF_DIR) destroy

deploy: check-terraform check-az ## Upload the current landing page to the existing Azure Storage account
	@test -n "$(STORAGE_ACCOUNT)" || { echo "Storage account not found. Apply Terraform first or run 'make deploy STORAGE_ACCOUNT=<name>'."; exit 1; }
	az storage blob service-properties update \
		--account-name "$(STORAGE_ACCOUNT)" \
		--static-website true \
		--index-document index.html \
		--404-document 404.html \
		--auth-mode login
	@for file in $(PUBLIC_FILES); do \
		az storage blob upload \
			--account-name "$(STORAGE_ACCOUNT)" \
			--container-name '$$web' \
			--name "$$file" \
			--file "$$file" \
			--overwrite true \
			--auth-mode login || exit 1; \
	done
	az storage blob upload-batch \
		--account-name "$(STORAGE_ACCOUNT)" \
		--destination '$$web' \
		--destination-path assets/img \
		--source assets/img \
		--overwrite true \
		--auth-mode login
	@echo "Deployed to $$(terraform -chdir=$(TF_DIR) output -raw website_url 2>/dev/null || true)"

run: check-python ## Run the landing page locally (PORT=8000 by default)
	@echo "Serving http://localhost:$(PORT)"
	python3 -m http.server $(PORT)

clean: ## Remove the saved Terraform plan
	rm -f "$(TF_DIR)/$(TF_PLAN)"