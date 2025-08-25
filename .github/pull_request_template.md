# Pull Request

## Description
<!-- Provide a clear and concise description of your changes -->

## Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🧹 Code cleanup/refactoring
- [ ] 🧪 Test improvements
- [ ] 🔧 CI/CD improvements

## Related Issues
<!-- Link any related issues using "Fixes #123" or "Relates to #123" -->
- Fixes #
- Relates to #

## Changes Made
<!-- List the specific changes you made -->
- 
- 
- 

## Testing
<!-- Describe how you tested your changes -->
- [ ] ✅ Unit tests pass (`make test` or `tests/run_tests.sh`)
- [ ] ✅ Integration tests pass (`tests/integration_test.sh`)
- [ ] ✅ Manual testing completed
- [ ] ✅ OpenTofu validation passes (`make validate`)
- [ ] ✅ Code formatting is correct (`make fmt`)

### Test Cases
<!-- Describe specific test scenarios you covered -->
- [ ] Tested with default configuration
- [ ] Tested with custom configuration
- [ ] Tested cluster creation and destruction
- [ ] Tested monitoring stack (if applicable)
- [ ] Tested error scenarios

## Configuration Impact
<!-- If your changes affect configuration, describe the impact -->
- [ ] No configuration changes
- [ ] Backward compatible configuration changes
- [ ] New optional configuration options
- [ ] ⚠️ Breaking configuration changes (describe migration path below)

### Migration Path (if breaking changes)
<!-- If this introduces breaking changes, describe how users should migrate -->

## Documentation
- [ ] ✅ Updated README.md if needed
- [ ] ✅ Updated CONTRIBUTING.md if needed  
- [ ] ✅ Updated CLAUDE.md if needed
- [ ] ✅ Added/updated code comments
- [ ] ✅ Added/updated examples in `tf/terraform.tfvars.example`

## Deployment Notes
<!-- Any special deployment considerations -->
- [ ] No special deployment needed
- [ ] Requires `tofu init` due to provider changes
- [ ] Requires configuration updates
- [ ] Requires manual cleanup steps

## Screenshots (if applicable)
<!-- Add screenshots to help explain your changes -->

## Checklist
<!-- Ensure all items are completed before submitting -->
- [ ] 📝 My code follows the project's style guidelines
- [ ] 🔍 I have performed a self-review of my code
- [ ] 💬 I have commented my code, particularly in hard-to-understand areas
- [ ] 📖 I have made corresponding changes to the documentation
- [ ] ⚠️ My changes generate no new warnings or errors
- [ ] 🧪 I have added tests that prove my fix is effective or that my feature works
- [ ] 🟢 New and existing unit tests pass locally with my changes
- [ ] 🔗 Any dependent changes have been merged and published

## Additional Notes
<!-- Any additional information that reviewers should know -->

---

### For Maintainers
<!-- This section is for maintainer use -->
- [ ] Labels applied appropriately
- [ ] Milestone assigned (if applicable)
- [ ] Reviewed for security implications
- [ ] Breaking change noted in description and documented