# k3d-local Tests

This directory contains tests for the k3d-local project.

## Test Types

### 1. Unit Tests (`run_tests.sh`)

Fast validation tests that check:
- OpenTofu/Terraform configuration syntax and formatting
- File structure and completeness
- Variable definitions and validation rules
- Security best practices
- Documentation completeness

**Usage:**
```bash
cd tests/
./run_tests.sh
```

**Requirements:**
- OpenTofu or Terraform
- No running cluster required

### 2. Integration Tests (`integration_test.sh`)

End-to-end tests that:
- Create a real k3d cluster
- Deploy the monitoring stack
- Verify cluster functionality
- Test basic Kubernetes operations
- Clean up resources

**Usage:**
```bash
cd tests/
./integration_test.sh
```

**Requirements:**
- Colima running (`colima start`)
- All dependencies installed (k3d, kubectl, etc.)
- Available ports 8081 and 8444
- ~5-10 minutes runtime

**Environment Variables:**
- `CLEANUP_ON_FAILURE=false` - Skip cleanup on test failure for debugging

## Running Tests

### Quick Validation (Recommended)
```bash
make test
```

### Manual Test Execution
```bash
# Unit tests only
cd tests/
./run_tests.sh

# Integration tests (requires running Colima)
cd tests/
./integration_test.sh

# Integration tests with no cleanup on failure
cd tests/
CLEANUP_ON_FAILURE=false ./integration_test.sh
```

### CI/CD Integration

For automated testing in CI/CD pipelines:

```bash
# In CI environment
./tests/run_tests.sh

# For full integration testing (requires Docker/container runtime)
# Start container runtime first, then:
./tests/integration_test.sh
```

## Test Output

### Successful Run
```
==========================================
       k3d-local Test Suite
==========================================
[INFO] Checking prerequisites...
[INFO] Using tofu for infrastructure management
[INFO] Running test: OpenTofu format check
✓ PASS: OpenTofu format check
...
==========================================
           Test Results
==========================================
Tests run: 15
Tests passed: 15
Tests failed: 0

🎉 All tests passed!
The k3d-local configuration is ready for deployment.
```

### Failed Run
```
✗ FAIL: OpenTofu format check
[ERROR] Command failed: cd ../tf && tofu fmt -check
...
❌ Some tests failed.
Please fix the issues above before deployment.
```

## Test Development

### Adding New Tests

#### Unit Tests
Add new test cases to `run_tests.sh`:
```bash
run_test "Test description" "command_to_run"
```

#### Integration Tests
Add new verification steps to `integration_test.sh`:
```bash
step "New integration test step..."
# Add test logic here
```

### Test Categories

1. **Configuration Tests** - Validate OpenTofu syntax and structure
2. **Security Tests** - Check for hardcoded secrets and proper permissions
3. **Documentation Tests** - Verify documentation completeness
4. **Functionality Tests** - Test actual cluster operations
5. **Cleanup Tests** - Ensure proper resource cleanup

### Best Practices

- Use descriptive test names
- Include error messages for debugging
- Test both success and failure paths
- Clean up resources after tests
- Use timeouts for operations that might hang
- Provide clear output for CI/CD systems

## Troubleshooting

### Common Issues

1. **Colima not running**
   ```
   colima start
   ```

2. **Port conflicts**
   - Integration tests use ports 8081 and 8444
   - Ensure these ports are available

3. **Test cleanup failures**
   ```bash
   # Manual cleanup
   k3d cluster delete k3d-test-*
   ```

4. **Permission issues**
   ```bash
   chmod +x tests/*.sh
   ```

### Debugging Failed Tests

1. **Check prerequisites:**
   ```bash
   make check-deps
   ```

2. **Run tests with verbose output:**
   ```bash
   set -x
   ./run_tests.sh
   ```

3. **Keep resources for inspection:**
   ```bash
   CLEANUP_ON_FAILURE=false ./integration_test.sh
   ```

4. **Check logs:**
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```