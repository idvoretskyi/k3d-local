# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated testing, validation, and releases.

## Workflows Overview

### 🔍 CI (`ci.yml`)
**Trigger**: Push to `main`/`develop`, Pull Requests  
**Purpose**: Core validation and testing pipeline

**Jobs**:
- **validate**: OpenTofu formatting, syntax validation, security checks
- **test**: Unit tests execution
- **docs**: Documentation completeness verification  
- **config-validation**: Multiple configuration scenario testing
- **makefile**: Makefile targets validation
- **security**: Secret scanning and security checks
- **health-check**: Overall project health assessment

### 🧪 Integration Tests (`integration.yml`)
**Trigger**: Manual dispatch, Daily at 2 AM UTC  
**Purpose**: Full end-to-end testing with real k3d clusters

**Jobs**:
- **integration-test**: Complete deployment and functionality testing
- **config-matrix-test**: Testing different cluster configurations
- **performance-test**: Resource usage and performance validation

### 📦 Release (`release.yml`)
**Trigger**: Version tags (`v*.*.*`), Manual dispatch  
**Purpose**: Automated release creation and artifact publishing

**Jobs**:
- **validate-release**: Pre-release validation
- **create-release**: GitHub release creation with assets
- **post-release**: Post-release tasks and notifications
- **test-release**: Smoke testing of release artifacts

### 🔀 Pull Request (`pr.yml`) 
**Trigger**: Pull Request events  
**Purpose**: PR-specific validation and checks

**Jobs**:
- **check-pr-status**: Draft PR handling
- **pr-validation**: Code quality and breaking change detection
- **pr-security**: Security scanning for PR changes
- **pr-size-check**: PR size and complexity analysis
- **pr-summary**: Overall PR validation summary

## Workflow Features

### Security
- **Secret Scanning**: Trufflehog integration for credential detection
- **Sensitive File Detection**: Prevents accidental commit of secrets
- **Security Best Practices**: Validates OpenTofu security configurations

### Testing Coverage
- **Unit Tests**: Fast validation tests (`tests/run_tests.sh`)
- **Integration Tests**: Real cluster deployment testing
- **Configuration Testing**: Multiple config scenario validation
- **Documentation Testing**: Ensures docs are up-to-date

### Quality Assurance
- **Code Formatting**: OpenTofu code formatting validation
- **Configuration Validation**: Syntax and semantic validation
- **Documentation Consistency**: Links and structure validation
- **Breaking Change Detection**: Identifies potentially breaking changes

### Release Management
- **Automated Releases**: Version-based release creation
- **Artifact Generation**: Release archives with checksums
- **Changelog Generation**: Automatic changelog creation
- **Release Validation**: Post-release verification

## Badge Status

The following badges are available for README.md:

```markdown
[![CI](https://github.com/idvoretskyi/k3d-local/workflows/CI/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/ci.yml)
[![Integration Tests](https://github.com/idvoretskyi/k3d-local/workflows/Integration%20Tests/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/integration.yml)
[![Release](https://github.com/idvoretskyi/k3d-local/workflows/Release/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

## Local Development

### Running Tests Locally

Before pushing changes, run tests locally:

```bash
# Unit tests (fast)
make test
# or
cd tests/ && ./run_tests.sh

# Integration tests (requires Colima)
cd tests/ && ./integration_test.sh

# Code validation
make lint
make validate
```

### Testing Workflow Changes

To test workflow changes:

1. Create a feature branch
2. Make your changes to `.github/workflows/`
3. Push to your fork
4. Create a PR to see workflow validation
5. Use manual dispatch for integration tests

### Workflow Debugging

For workflow debugging:

```bash
# Check workflow syntax locally (if using act)
act --list
act -n  # Dry run

# Check OpenTofu configuration locally
cd tf/
tofu init -backend=false
tofu validate
tofu fmt -check
```

## Maintenance

### Updating Dependencies
- **OpenTofu Version**: Update `TF_VERSION` in workflow files
- **GitHub Actions**: Update action versions (e.g., `actions/checkout@v4`)
- **Tools**: Update tool versions in installation steps

### Adding New Tests
- **Unit Tests**: Add to `tests/run_tests.sh`
- **Integration Tests**: Add to `tests/integration_test.sh` 
- **Workflow Tests**: Add new jobs or steps to existing workflows

### Monitoring
- Review workflow run times and optimize for performance
- Monitor failure patterns and adjust timeouts
- Update test coverage as project evolves