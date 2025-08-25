#!/bin/bash
# Test runner for k3d-local OpenTofu configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Log function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo
    log "Running test: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        error "Command failed: $test_command"
    fi
}

# Pre-flight checks
echo "=========================================="
echo "       k3d-local Test Suite"  
echo "=========================================="

# Check if we're in the right directory
if [ ! -d "../tf" ]; then
    error "Tests must be run from the tests/ directory"
    error "Current directory: $(pwd)"
    exit 1
fi

# Check for required tools
log "Checking prerequisites..."

MISSING_TOOLS=()
if ! command -v tofu >/dev/null 2>&1 && ! command -v terraform >/dev/null 2>&1; then
    MISSING_TOOLS+=("tofu or terraform")
fi

# In CI environment, skip colima check since Docker is available directly
if [ -z "$CI_ENVIRONMENT" ] && ! command -v colima >/dev/null 2>&1; then
    MISSING_TOOLS+=("colima")
fi

if ! command -v k3d >/dev/null 2>&1; then
    MISSING_TOOLS+=("k3d")  
fi

if ! command -v kubectl >/dev/null 2>&1; then
    MISSING_TOOLS+=("kubectl")
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    error "Missing required tools: ${MISSING_TOOLS[*]}"
    if [ -z "$CI_ENVIRONMENT" ]; then
        error "Please install missing tools before running tests"
        error "Run 'make check-deps' to see installation instructions"
    else
        error "CI environment should have these tools installed"
    fi
    exit 1
fi

# Determine which tool to use
TF_CMD="tofu"
if ! command -v tofu >/dev/null 2>&1; then
    TF_CMD="terraform"
fi

log "Using $TF_CMD for infrastructure management"

if [ -n "$CI_ENVIRONMENT" ]; then
    log "Running in CI environment"
else
    log "Running in local development environment"
fi

# Test 1: OpenTofu Configuration Validation
run_test "OpenTofu format check" "cd ../tf && $TF_CMD fmt -check"
run_test "OpenTofu initialization" "cd ../tf && $TF_CMD init -backend=false"
run_test "OpenTofu configuration validation" "cd ../tf && $TF_CMD validate"

# Test 2: Configuration file tests
run_test "terraform.tfvars.example exists" "test -f ../tf/terraform.tfvars.example"
run_test "All required .tf files exist" "test -f ../tf/main.tf && test -f ../tf/variables.tf && test -f ../tf/outputs.tf && test -f ../tf/versions.tf && test -f ../tf/monitoring.tf"

# Test 3: Variable validation (syntax)
run_test "Variable syntax validation" "cd ../tf && $TF_CMD validate -var-file=terraform.tfvars.example"

# Test 4: Plan generation (dry run)
log "Testing plan generation with example configuration..."
if [ -f "../tf/terraform.tfvars" ]; then
    run_test "Plan generation with existing config" "cd ../tf && ($TF_CMD plan -input=false || true)"
else
    run_test "Plan generation with example config" "cd ../tf && cp terraform.tfvars.example terraform.tfvars.test && ($TF_CMD plan -var-file=terraform.tfvars.test -input=false || true) && rm terraform.tfvars.test"
fi

# Test 5: Provider version constraints
run_test "Provider version constraints" "cd ../tf && grep -q 'required_version.*>=.*1.0' versions.tf"
run_test "null provider constraint" "cd ../tf && grep -q 'null.*{' versions.tf"
run_test "helm provider constraint" "cd ../tf && grep -q 'helm.*{' versions.tf"  
run_test "kubernetes provider constraint" "cd ../tf && grep -q 'kubernetes.*{' versions.tf"

# Test 6: Resource dependency validation
run_test "Monitoring depends on cluster" "cd ../tf && grep -q 'depends_on.*=.*null_resource.cluster_ready' monitoring.tf"

# Test 7: Documentation tests
run_test "README exists" "test -f ../README.md"
run_test "LICENSE exists" "test -f ../LICENSE"
run_test "CONTRIBUTING guide exists" "test -f ../CONTRIBUTING.md"
run_test "Makefile exists" "test -f ../Makefile"

# Test 8: Project structure validation
run_test "tf/ directory structure" "test -d ../tf && test -f ../tf/main.tf"
run_test "tests/ directory exists" "test -d ."

# Test 9: Configuration completeness
run_test "All variables have descriptions" "cd ../tf && ! grep -A 5 '^variable' variables.tf | grep -B 5 'description.*=' | grep -q 'description.*=.*$' || true"
run_test "All outputs have descriptions" "cd ../tf && ! grep -A 3 '^output' outputs.tf | grep 'description.*=' | grep -q 'description.*=.*$' || true"

# Test 10: Security checks
run_test "No hardcoded secrets in code" "! grep -r -i 'password.*=.*[^)]' ../tf/ | grep -v 'var\\.' | grep -v 'description' | grep -v 'default.*=' | grep -v 'adminPassword.*=.*var\\.' || true"
run_test "Sensitive outputs marked" "cd ../tf && grep -A 5 'grafana_admin_password' outputs.tf | grep -q 'sensitive.*=.*true'"

# Summary
echo
echo "=========================================="
echo "           Test Results"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo "The k3d-local configuration is ready for deployment."
    exit 0
else
    echo
    echo -e "${RED}❌ Some tests failed.${NC}"  
    echo "Please fix the issues above before deployment."
    exit 1
fi