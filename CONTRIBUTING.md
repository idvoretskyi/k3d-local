# Contributing to k3d-local

Thank you for your interest in contributing to k3d-local! This document provides guidelines and information about contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

### Prerequisites

- [Colima](https://github.com/abiosoft/colima) - Container runtime for macOS
- [OpenTofu](https://opentofu.org/) or [Terraform](https://terraform.io/) >= 1.0
- [k3d](https://k3d.io/) >= 5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Local Development

1. Start Colima:
   ```bash
   colima start
   ```

2. Initialize OpenTofu:
   ```bash
   cd tf/
   tofu init
   ```

3. Copy and customize configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars as needed
   ```

4. Plan and apply:
   ```bash
   tofu plan
   tofu apply
   ```

## Code Standards

### OpenTofu/Terraform Code

- Use consistent formatting: `tofu fmt`
- Validate configuration: `tofu validate`
- Add comments for complex logic
- Use meaningful variable names and descriptions
- Include proper validation rules for variables
- Follow the existing code structure and patterns

### Documentation

- Update README.md for any user-facing changes
- Update CLAUDE.md for development environment changes
- Include examples for new features
- Document breaking changes clearly

## Testing

Before submitting a pull request:

1. Run the test suite:
   ```bash
   cd tests/
   ./run_tests.sh
   ```

2. Test manual workflows:
   - Create a cluster with default settings
   - Create a cluster with custom configuration
   - Verify monitoring stack deployment
   - Test cluster destruction

3. Validate OpenTofu code:
   ```bash
   cd tf/
   tofu fmt -check
   tofu validate
   ```

## Pull Request Process

1. **Create a descriptive title** - Summarize your changes clearly
2. **Provide context** - Explain what problem you're solving
3. **Include testing details** - How did you test your changes?
4. **Update documentation** - Keep docs in sync with code changes
5. **Link issues** - Reference any related GitHub issues

### Pull Request Template

```
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested cluster creation with default configuration
- [ ] Tested cluster creation with custom configuration  
- [ ] Tested monitoring stack deployment
- [ ] Tested cluster destruction
- [ ] Ran automated tests (`./tests/run_tests.sh`)

## Documentation
- [ ] Updated README.md if needed
- [ ] Updated CLAUDE.md if needed
- [ ] Added/updated examples if needed
```

## Issue Reporting

When reporting issues:

1. **Use the issue templates** provided
2. **Include environment details**:
   - macOS version
   - Colima version
   - k3d version
   - OpenTofu/Terraform version
3. **Provide reproduction steps**
4. **Include relevant logs** and error messages
5. **Attach configuration files** (remove sensitive data)

## Code of Conduct

Please be respectful and inclusive in all interactions. This project welcomes contributions from developers of all skill levels and backgrounds.

## Questions?

If you have questions about contributing, please:

1. Check existing issues and discussions
2. Open a new issue with the "question" label
3. Join discussions in existing issues

Thank you for contributing to k3d-local!