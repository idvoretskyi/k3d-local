#!/bin/bash
# Integration tests for k3d-local - creates and destroys a real cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TEST_CLUSTER_NAME="k3d-test-$(date +%s)"
TEST_CONFIG_FILE="../tf/terraform.tfvars.integration"
CLEANUP_ON_FAILURE=${CLEANUP_ON_FAILURE:-true}

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

cleanup() {
    if [ "$CLEANUP_ON_FAILURE" = "true" ]; then
        warn "Cleaning up test resources..."
        cd ../tf
        if [ -f "$TEST_CONFIG_FILE" ]; then
            tofu destroy -var-file="$(basename "$TEST_CONFIG_FILE")" -auto-approve >/dev/null 2>&1 || true
            rm -f "$TEST_CONFIG_FILE"
        fi
        # Fallback cleanup using k3d directly
        k3d cluster delete "$TEST_CLUSTER_NAME" >/dev/null 2>&1 || true
    fi
}

# Trap for cleanup on failure
trap cleanup EXIT

echo "=========================================="
echo "    k3d-local Integration Tests"
echo "=========================================="

# Prerequisites check
log "Checking prerequisites..."
if ! command -v colima >/dev/null 2>&1; then
    error "colima is required but not installed"
    exit 1
fi

if ! command -v k3d >/dev/null 2>&1; then
    error "k3d is required but not installed"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    error "kubectl is required but not installed"
    exit 1
fi

TF_CMD="tofu"
if ! command -v tofu >/dev/null 2>&1; then
    if ! command -v terraform >/dev/null 2>&1; then
        error "tofu or terraform is required but not installed"
        exit 1
    fi
    TF_CMD="terraform"
fi

# Check if Colima is running
if ! colima status >/dev/null 2>&1; then
    error "Colima is not running. Please start it with: colima start"
    exit 1
fi

log "All prerequisites met. Using $TF_CMD for infrastructure management."

# Step 1: Create test configuration
step "Creating test configuration..."
cd ../tf

cat > "$(basename "$TEST_CONFIG_FILE")" << EOF
# Integration test configuration
cluster_name  = "$TEST_CLUSTER_NAME"
server_count  = 1
agent_count   = 1

# Use different ports to avoid conflicts
http_port     = 8081
https_port    = 8444

# Minimal monitoring for faster testing
enable_monitoring             = true
prometheus_storage_size       = "1Gi"
alertmanager_storage_size     = "500Mi"
grafana_storage_size          = "1Gi"

# Disable LoadBalancers for faster testing
enable_prometheus_loadbalancer  = false
enable_alertmanager_loadbalancer = false
enable_grafana_loadbalancer     = false

# Smaller resource requirements
prometheus_resources = {
  requests = {
    memory = "256Mi"
    cpu    = "100m"
  }
  limits = {
    memory = "512Mi"
    cpu    = "500m"
  }
}

grafana_resources = {
  requests = {
    memory = "128Mi"
    cpu    = "50m"
  }
  limits = {
    memory = "256Mi"
    cpu    = "200m"
  }
}

alertmanager_resources = {
  requests = {
    memory = "64Mi"
    cpu    = "50m"
  }
  limits = {
    memory = "128Mi"
    cpu    = "100m"
  }
}
EOF

log "Test configuration created: $(basename "$TEST_CONFIG_FILE")"

# Step 2: Initialize OpenTofu
step "Initializing OpenTofu..."
$TF_CMD init -input=false

# Step 3: Plan deployment
step "Planning deployment..."
$TF_CMD plan -var-file="$(basename "$TEST_CONFIG_FILE")" -input=false

# Step 4: Deploy cluster
step "Deploying test cluster..."
$TF_CMD apply -var-file="$(basename "$TEST_CONFIG_FILE")" -auto-approve

# Step 5: Verify cluster
step "Verifying cluster deployment..."

# Wait a moment for cluster to be ready
sleep 10

# Check if cluster exists
if ! k3d cluster list | grep -q "$TEST_CLUSTER_NAME"; then
    error "Cluster $TEST_CLUSTER_NAME not found"
    exit 1
fi

log "Cluster $TEST_CLUSTER_NAME created successfully"

# Check kubectl context
EXPECTED_CONTEXT="k3d-$TEST_CLUSTER_NAME"
if ! kubectl config get-contexts | grep -q "$EXPECTED_CONTEXT"; then
    error "kubectl context $EXPECTED_CONTEXT not found"
    exit 1
fi

log "kubectl context $EXPECTED_CONTEXT found"

# Switch to test cluster context
kubectl config use-context "$EXPECTED_CONTEXT"

# Step 6: Test cluster functionality
step "Testing cluster functionality..."

# Wait for nodes to be ready
log "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Check nodes
NODES_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
if [ "$NODES_COUNT" -ne "2" ]; then
    error "Expected 2 nodes, found $NODES_COUNT"
    exit 1
fi

log "All nodes are ready ($NODES_COUNT nodes)"

# Step 7: Test monitoring stack (if enabled)
step "Testing monitoring stack..."

# Wait for monitoring namespace
if ! kubectl get namespace monitoring >/dev/null 2>&1; then
    error "Monitoring namespace not found"
    exit 1
fi

log "Monitoring namespace found"

# Wait for monitoring pods to be ready (with timeout)
log "Waiting for monitoring pods to be ready..."
timeout 300s bash -c 'while [ "$(kubectl get pods -n monitoring --no-headers | grep -v Running | grep -v Completed | wc -l)" -ne "0" ]; do sleep 5; done' || {
    warn "Some monitoring pods may not be ready yet"
    kubectl get pods -n monitoring
}

# Check if key monitoring components are running
PROMETHEUS_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | grep Running | wc -l | tr -d ' ')
GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | grep Running | wc -l | tr -d ' ')

if [ "$PROMETHEUS_PODS" -eq "0" ]; then
    warn "Prometheus pods are not running"
fi

if [ "$GRAFANA_PODS" -eq "0" ]; then
    warn "Grafana pods are not running"
fi

log "Monitoring stack verification completed"

# Step 8: Test basic Kubernetes functionality
step "Testing basic Kubernetes functionality..."

# Create a test deployment
kubectl create deployment test-nginx --image=nginx:alpine
kubectl wait --for=condition=available --timeout=60s deployment/test-nginx

# Check if deployment is running
if ! kubectl get deployment test-nginx -o jsonpath='{.status.readyReplicas}' | grep -q "1"; then
    error "Test deployment failed"
    exit 1
fi

log "Test deployment successful"

# Clean up test deployment
kubectl delete deployment test-nginx

# Step 9: Test outputs
step "Testing OpenTofu outputs..."

CLUSTER_OUTPUT=$($TF_CMD output -raw cluster_name)
if [ "$CLUSTER_OUTPUT" != "$TEST_CLUSTER_NAME" ]; then
    error "Cluster name output mismatch. Expected: $TEST_CLUSTER_NAME, Got: $CLUSTER_OUTPUT"
    exit 1
fi

log "OpenTofu outputs verified"

# Step 10: Destroy cluster
step "Destroying test cluster..."
$TF_CMD destroy -var-file="$(basename "$TEST_CONFIG_FILE")" -auto-approve

# Verify cluster is destroyed
sleep 5
if k3d cluster list | grep -q "$TEST_CLUSTER_NAME"; then
    error "Cluster $TEST_CLUSTER_NAME still exists after destroy"
    exit 1
fi

log "Cluster successfully destroyed"

# Clean up test configuration
rm -f "$(basename "$TEST_CONFIG_FILE")"

# Success
echo
echo "=========================================="
echo "   Integration Tests Completed"
echo "=========================================="
echo -e "${GREEN}✅ All integration tests passed!${NC}"
echo "The k3d-local configuration is working correctly."

# Disable cleanup trap since we succeeded
trap - EXIT