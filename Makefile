# Makefile for k3d-local development

.PHONY: help init plan apply destroy fmt validate test clean lint

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Terraform/OpenTofu commands
init: ## Initialize OpenTofu
	cd tf && tofu init

plan: ## Plan infrastructure changes
	cd tf && tofu plan

apply: ## Apply infrastructure changes
	cd tf && tofu apply

destroy: ## Destroy infrastructure
	cd tf && tofu destroy

# Code quality
fmt: ## Format OpenTofu code
	cd tf && tofu fmt -recursive

validate: ## Validate OpenTofu configuration
	cd tf && tofu validate

lint: fmt validate ## Run all linting and formatting

# Testing
test: ## Run tests
	@if [ -f tests/run_tests.sh ]; then \
		cd tests && ./run_tests.sh; \
	else \
		echo "No tests found. Run 'make create-tests' to create test structure."; \
	fi

# Development helpers
create-config: ## Create terraform.tfvars from example
	@if [ ! -f tf/terraform.tfvars ]; then \
		cp tf/terraform.tfvars.example tf/terraform.tfvars; \
		echo "Created tf/terraform.tfvars from example. Please customize it."; \
	else \
		echo "tf/terraform.tfvars already exists."; \
	fi

create-tests: ## Create basic test structure
	@mkdir -p tests
	@if [ ! -f tests/run_tests.sh ]; then \
		echo "#!/bin/bash" > tests/run_tests.sh; \
		echo "# Basic test runner for k3d-local" >> tests/run_tests.sh; \
		echo "set -e" >> tests/run_tests.sh; \
		echo "" >> tests/run_tests.sh; \
		echo "echo 'Running k3d-local tests...'" >> tests/run_tests.sh; \
		echo "" >> tests/run_tests.sh; \
		echo "# Test 1: Validate Terraform configuration" >> tests/run_tests.sh; \
		echo "echo 'Testing OpenTofu configuration...'" >> tests/run_tests.sh; \
		echo "cd ../tf && tofu validate" >> tests/run_tests.sh; \
		echo "cd ../tf && tofu fmt -check" >> tests/run_tests.sh; \
		echo "" >> tests/run_tests.sh; \
		echo "echo 'All tests passed!'" >> tests/run_tests.sh; \
		chmod +x tests/run_tests.sh; \
		echo "Created basic test structure in tests/"; \
	else \
		echo "tests/run_tests.sh already exists."; \
	fi

# Cleanup
clean: ## Clean up temporary files and state
	rm -f tf/.terraform.lock.hcl
	rm -rf tf/.terraform/
	rm -f tf/terraform.tfstate.backup

# Documentation
docs: ## Generate/update documentation
	@echo "Updating documentation..."
	@echo "Consider running: terraform-docs markdown table tf/ > tf/README.md"

# Prerequisites check
check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@echo ""
	@command -v colima >/dev/null 2>&1 || { \
		echo "❌ colima is required but not installed."; \
		echo "   Install with: brew install colima"; \
		echo ""; \
	}
	@command -v tofu >/dev/null 2>&1 || command -v terraform >/dev/null 2>&1 || { \
		echo "❌ OpenTofu or Terraform is required but not installed."; \
		echo "   Install OpenTofu with: brew install opentofu"; \
		echo "   Or Terraform with: brew install terraform"; \
		echo ""; \
	}
	@command -v k3d >/dev/null 2>&1 || { \
		echo "❌ k3d is required but not installed."; \
		echo "   Install with: brew install k3d"; \
		echo ""; \
	}
	@command -v kubectl >/dev/null 2>&1 || { \
		echo "❌ kubectl is required but not installed."; \
		echo "   Install with: brew install kubectl"; \
		echo ""; \
	}
	@if command -v colima >/dev/null 2>&1 && \
	   (command -v tofu >/dev/null 2>&1 || command -v terraform >/dev/null 2>&1) && \
	   command -v k3d >/dev/null 2>&1 && \
	   command -v kubectl >/dev/null 2>&1; then \
		echo "✅ All dependencies are installed!"; \
	else \
		echo "⚠️  Some dependencies are missing. Install them with:"; \
		echo "   brew install colima k3d opentofu kubectl"; \
		exit 1; \
	fi

# Quick setup for new users
setup: check-deps create-config ## Quick setup for new users
	@echo "Setting up k3d-local..."
	@echo "1. Dependencies checked ✓"
	@echo "2. Configuration created ✓"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Start Colima: colima start"
	@echo "  2. Customize tf/terraform.tfvars if needed"
	@echo "  3. Initialize: make init"
	@echo "  4. Deploy: make apply"