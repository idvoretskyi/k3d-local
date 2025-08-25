# k3d Local Development Environment

[![CI](https://github.com/idvoretskyi/k3d-local/workflows/CI/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/ci.yml)
[![Integration Tests](https://github.com/idvoretskyi/k3d-local/workflows/Integration%20Tests/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/integration.yml)
[![Release](https://github.com/idvoretskyi/k3d-local/workflows/Release/badge.svg)](https://github.com/idvoretskyi/k3d-local/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-%E2%89%A5%201.0-blue.svg)](https://opentofu.org/)
[![k3d](https://img.shields.io/badge/k3d-%E2%89%A5%205.0-green.svg)](https://k3d.io/)

Automated k3d cluster provisioning for macOS using OpenTofu and Colima. A lightweight Kubernetes development environment that runs locally without Docker Desktop.

## Quick Start

```bash
# Install dependencies
brew install colima k3d opentofu kubectl

# Start container runtime
colima start --cpu 4 --memory 8

# Deploy cluster (using Make)
make setup && make init && make apply

# Or manually
cd tf/ && tofu init && tofu apply
```

**Access your cluster:**
```bash
kubectl config use-context k3d-local-dev
kubectl get nodes
```

## What You Get

- ✅ **Local k3d cluster** with configurable size and ports
- ✅ **Monitoring stack** - Prometheus, Grafana, and Alertmanager included  
- ✅ **No Docker Desktop** - Uses Colima for macOS
- ✅ **Make automation** - Simple commands for all operations
- ✅ **Comprehensive tests** - Unit and integration testing

## Configuration

Create `tf/terraform.tfvars` to customize your cluster:

```hcl
cluster_name = "my-dev-cluster"
server_count = 1
agent_count  = 2
enable_monitoring = true
grafana_admin_password = "admin"
```

See `tf/terraform.tfvars.example` for all available options.

## Monitoring

Access your monitoring stack:

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093

## Common Commands

```bash
make help           # Show all commands
make test           # Run tests  
make destroy        # Delete cluster
colima stop         # Stop container runtime

# Manual commands
cd tf/ && tofu output    # View cluster info
kubectl get pods -A     # Check all pods
```

## Troubleshooting

**Colima not running?**
```bash
colima start --cpu 4 --memory 8
```

**Port conflicts?** Edit `tf/terraform.tfvars` to change ports.

**Need help?** Check [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue.

## License

MIT License - see [LICENSE](LICENSE) for details.