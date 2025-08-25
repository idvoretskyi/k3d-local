output "cluster_name" {
  description = "Name of the created k3d cluster"
  value       = k3d_cluster.main.name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  sensitive   = true
  value       = k3d_cluster.main.kubeconfig.0.cluster_ca_certificate != null ? "https://0.0.0.0:${k3d_cluster.main.kubeconfig.0.port}" : "Check ~/.kube/config for endpoint"
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "~/.kube/config (merged by k3d)"
}

output "cluster_info" {
  description = "Complete cluster information"
  value = {
    name         = k3d_cluster.main.name
    servers      = k3d_cluster.main.servers
    agents       = k3d_cluster.main.agents
    network      = k3d_cluster.main.network
    k3s_image    = var.k3s_image
  }
}

output "port_mappings" {
  description = "Port mappings for the cluster"
  value = {
    http_port  = var.http_port
    https_port = var.https_port
    additional = var.additional_ports
  }
}

output "access_urls" {
  description = "URLs for accessing services through the LoadBalancer"
  value = {
    http  = "http://localhost:${var.http_port}"
    https = "https://localhost:${var.https_port}"
  }
}

output "kubectl_context" {
  description = "kubectl context name for the cluster"
  value       = "k3d-${k3d_cluster.main.name}"
}

# Monitoring Outputs
output "monitoring_enabled" {
  description = "Whether monitoring stack is enabled"
  value       = var.enable_monitoring
}

output "monitoring_namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = var.enable_monitoring ? var.monitoring_namespace : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.enable_monitoring ? var.grafana_admin_password : null
  sensitive   = true
}

output "monitoring_access_urls" {
  description = "URLs for accessing monitoring services via LoadBalancer"
  value = var.enable_monitoring ? {
    grafana = var.enable_grafana_loadbalancer ? "http://localhost:3000" : "Use port-forward: kubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-grafana 3000:80"
    prometheus = var.enable_prometheus_loadbalancer ? "http://localhost:9090" : "Use port-forward: kubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-prometheus 9090:9090"
    alertmanager = var.enable_alertmanager_loadbalancer ? "http://localhost:9093" : "Use port-forward: kubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-alertmanager 9093:9093"
  } : null
}

output "monitoring_commands" {
  description = "Useful commands for monitoring stack"
  value = var.enable_monitoring ? "Monitoring Stack Commands:\n\n# Check monitoring pods\nkubectl get pods -n ${var.monitoring_namespace}\n\n# Port-forward Grafana (if LoadBalancer not enabled)\nkubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-grafana 3000:80\n\n# Port-forward Prometheus (if LoadBalancer not enabled)\nkubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-prometheus 9090:9090\n\n# Port-forward Alertmanager (if LoadBalancer not enabled)\nkubectl port-forward -n ${var.monitoring_namespace} svc/kube-prometheus-stack-alertmanager 9093:9093\n\n# View Grafana logs\nkubectl logs -n ${var.monitoring_namespace} -l app.kubernetes.io/name=grafana\n\n# View Prometheus logs\nkubectl logs -n ${var.monitoring_namespace} -l app.kubernetes.io/name=prometheus" : null
}

output "next_steps" {
  description = "Instructions for next steps after cluster creation"
  sensitive   = true
  value = <<-EOT
  Your k3d cluster '${k3d_cluster.main.name}' has been created successfully!
  
  Next steps:
  1. Set kubectl context: kubectl config use-context k3d-${k3d_cluster.main.name}
  2. Verify cluster: kubectl cluster-info
  3. Check nodes: kubectl get nodes
  4. Deploy applications: kubectl apply -f your-manifests/
  
  Access URLs:
  - HTTP services: http://localhost:${var.http_port}
  - HTTPS services: https://localhost:${var.https_port}
  
  ${var.enable_monitoring ? "Monitoring Stack:" : ""}
  ${var.enable_monitoring && var.enable_grafana_loadbalancer ? "- Grafana: http://localhost:3000 (admin/${var.grafana_admin_password})" : ""}
  ${var.enable_monitoring && var.enable_prometheus_loadbalancer ? "- Prometheus: http://localhost:9090" : ""}
  ${var.enable_monitoring && var.enable_alertmanager_loadbalancer ? "- Alertmanager: http://localhost:9093" : ""}
  ${var.enable_monitoring && (!var.enable_grafana_loadbalancer || !var.enable_prometheus_loadbalancer || !var.enable_alertmanager_loadbalancer) ? "\nUse 'tofu output monitoring_commands' for port-forward instructions" : ""}
  EOT
}
