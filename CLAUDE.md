# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a k3d-based local Kubernetes development environment project designed specifically for macOS using Colima as the container runtime. k3d creates containerized k3s clusters, providing lightweight Kubernetes clusters for local development and testing of cloud-native applications without requiring Docker Desktop.

## Key Technologies

- **OpenTofu**: Open-source infrastructure as code tool (Terraform fork) for automated provisioning
- **Colima**: Container runtime for macOS (alternative to Docker Desktop)
- **k3d**: Lightweight wrapper to run k3s (Rancher Lab's minimal Kubernetes distribution) in containers
- **k3s**: Lightweight Kubernetes distribution
- **containerd**: Container runtime used by Colima
- **kubectl**: Kubernetes command-line tool
- **Helm**: Package manager for Kubernetes applications
- **kube-prometheus-stack**: Complete monitoring stack with Prometheus, Grafana, and Alertmanager
- **Prometheus**: Metrics collection and alerting system
- **Grafana**: Observability and visualization platform
- **Alertmanager**: Alert handling and notification routing

## Common Commands

### OpenTofu Infrastructure Management
```bash
# Navigate to OpenTofu directory
cd tf/

# Initialize OpenTofu (run first time or after provider changes)
tofu init

# Plan infrastructure changes
tofu plan

# Apply infrastructure (create k3d cluster)
tofu apply

# Show current infrastructure state
tofu show

# Destroy infrastructure (delete k3d cluster)
tofu destroy

# Validate configuration
tofu validate

# Format configuration files
tofu fmt

# Generate example variables file
cp terraform.tfvars.example terraform.tfvars
```

### Make-based Workflow (Recommended)
```bash
# Show all available targets
make help

# Quick setup for new users (check deps, create config)
make setup

# Initialize OpenTofu
make init

# Plan infrastructure changes
make plan

# Apply infrastructure changes
make apply

# Destroy infrastructure
make destroy

# Format and validate OpenTofu code
make fmt
make validate
make lint

# Run tests
make test

# Clean temporary files
make clean
```

### Colima Setup and Management
```bash
# Start Colima (required before using k3d)
colima start

# Start Colima with specific resources
colima start --cpu 4 --memory 8

# Check Colima status
colima status

# Stop Colima
colima stop

# Restart Colima
colima restart
```

### k3d Cluster Management
```bash
# Create a new k3d cluster
k3d cluster create <cluster-name>

# Create cluster with specific configuration
k3d cluster create <cluster-name> --port 8080:80@loadbalancer --port 8443:443@loadbalancer

# List existing clusters
k3d cluster list

# Start an existing cluster
k3d cluster start <cluster-name>

# Stop a cluster
k3d cluster stop <cluster-name>

# Delete a cluster
k3d cluster delete <cluster-name>

# Get kubeconfig for cluster
k3d kubeconfig get <cluster-name>
```

### Kubernetes Operations
```bash
# Check cluster status
kubectl cluster-info

# Get all resources
kubectl get all -A

# Apply Kubernetes manifests
kubectl apply -f manifests/

# Port forward services for local access
kubectl port-forward service/<service-name> <local-port>:<service-port>

# View logs
kubectl logs -f deployment/<deployment-name>
```

### Monitoring Stack Management
```bash
# Check monitoring stack status
kubectl get pods -n monitoring

# Access Grafana (admin/admin by default, or custom password)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Access Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Access Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Check monitoring services
kubectl get svc -n monitoring

# View Grafana admin password (if using terraform.tfvars)
tofu output grafana_admin_password

# Get monitoring access URLs
tofu output monitoring_access_urls

# Get monitoring commands
tofu output monitoring_commands
```

### Container Image Management
```bash
# Build images with Colima
docker build -t <image-name> .

# Import images into k3d cluster
k3d image import <image-name> -c <cluster-name>

# List images in cluster
docker exec -it k3d-<cluster-name>-server-0 crictl images

# Pull images through Colima
docker pull <image-name>
```

## Development Workflow

### Local Development Setup
1. **Quick Setup**: Use `make setup` to check dependencies and create configuration
2. **Colima Startup**: Ensure Colima is running before starting any container operations (`colima start`)
3. **OpenTofu Initialization**: Run `make init` or `cd tf/ && tofu init` to initialize the project
4. **Configuration**: Copy and customize `tf/terraform.tfvars.example` to `tf/terraform.tfvars` if needed
5. **Infrastructure Provisioning**: Run `make apply` or `cd tf/ && tofu apply` to create the k3d cluster with monitoring stack
6. **Cluster Access**: Use the provided kubeconfig and kubectl context from OpenTofu outputs
7. **Monitoring Access**: Access Grafana, Prometheus, and Alertmanager via LoadBalancer or port-forwarding
8. **Image Management**: Build or import container images using Colima and load them into the k3d cluster
9. **Manifest Deployment**: Apply Kubernetes manifests for applications and services
10. **Service Access**: Use the configured LoadBalancer ports or port-forwarding for local access

### Testing and Validation
The project includes comprehensive testing capabilities:

#### Unit Tests (Fast)
```bash
make test
# or
cd tests/ && ./run_tests.sh
```

#### Integration Tests (Complete)  
```bash
cd tests/ && ./integration_test.sh
```

#### Manual Testing
- **Cluster Health**: Verify cluster components are running correctly
- **Application Deployment**: Test application deployments in isolated local environment
- **Networking**: Validate service discovery and ingress configurations
- **Resource Management**: Monitor resource usage and limits with Grafana dashboards
- **Monitoring Stack**: Verify Prometheus metrics collection and Grafana visualizations
- **Alerting**: Test alert rules and Alertmanager notification routing

### Integration with CI/CD
- **Local Testing**: Test Kubernetes manifests locally before committing
- **Image Validation**: Verify container images work correctly in Kubernetes environment
- **Configuration Testing**: Validate ConfigMaps, Secrets, and other Kubernetes resources

## Architecture Patterns

### macOS-Native Container Development
- Colima provides Docker-compatible container runtime without Docker Desktop licensing requirements
- Applications designed to run in containers from the start
- Local development mirrors production Kubernetes environment
- Quick iteration cycles with immediate feedback on Apple Silicon and Intel Macs

### Microservices Testing
- Test service-to-service communication locally
- Validate service discovery and load balancing
- Test ingress and egress traffic patterns

### GitOps Preparation
- Local validation of manifest changes before pushing to production
- Testing of Helm charts and Kubernetes operators
- Validation of RBAC and security policies

### Infrastructure as Code Benefits
- **Reproducible Environments**: Consistent cluster configuration across team members
- **Version Control**: Infrastructure changes tracked in Git
- **Automated Provisioning**: Single command cluster creation and destruction
- **Configuration Management**: Centralized variable management for different scenarios

## Configuration

### Default Configuration
- **Cluster Name**: `local-dev`
- **HTTP Port**: `8080` (mapped to LoadBalancer port 80)
- **HTTPS Port**: `8443` (mapped to LoadBalancer port 443)
- **Servers**: 1 server node
- **Agents**: 2 agent nodes
- **K3s Configuration**: Traefik and ServiceLB disabled by default
- **Monitoring**: Enabled by default with kube-prometheus-stack
- **Grafana**: Default admin/admin credentials (customizable)
- **Prometheus**: 30-day data retention, 10Gi storage
- **Alertmanager**: 2Gi storage for alert data

### Customization
Customize the cluster by editing `terraform.tfvars`:
- Port mappings for different services
- Volume mounts for local development
- Environment variables
- Node labels and additional configuration
- Registry configuration for private images
- Monitoring stack configuration (enable/disable, resources, storage)
- Grafana admin password and dashboard configuration
- Prometheus retention and storage settings
- Alertmanager configuration and storage

## Port Management

OpenTofu-managed k3d clusters expose services through:
- **LoadBalancer**: Configured port mappings (default: 8080→80, 8443→443)
- **Additional Ports**: Customizable via `additional_ports` variable
- **NodePort**: Direct access to cluster nodes
- **Port Forward**: kubectl port-forward for development access
- **Ingress**: HTTP/HTTPS routing through ingress controllers