locals {
  cluster_name = var.cluster_name
  
  # Base port mappings
  base_ports = [
    {
      host      = var.http_port
      container = 80
      node      = "loadbalancer"
    },
    {
      host      = var.https_port
      container = 443
      node      = "loadbalancer"
    }
  ]
  
  # Monitoring ports (if enabled)
  monitoring_ports = var.enable_monitoring ? [
    {
      host      = 3000
      container = 3000
      node      = "loadbalancer"
    },
    {
      host      = 9090
      container = 9090
      node      = "loadbalancer"
    },
    {
      host      = 9093
      container = 9093
      node      = "loadbalancer"
    }
  ] : []
  
  # Combine all port mappings
  all_ports = concat(local.base_ports, local.monitoring_ports, var.additional_ports)
}

# k3d cluster resource
resource "k3d_cluster" "main" {
  name    = local.cluster_name
  servers = var.server_count
  agents  = var.agent_count
  
  # K3s configuration
  k3s {
    extra_args {
      server_args = var.k3s_server_args
      agent_args  = var.k3s_agent_args
    }
  }
  
  # Port mappings for LoadBalancer services
  dynamic "port" {
    for_each = local.all_ports
    content {
      host_port      = port.value.host
      container_port = port.value.container
      node_filters   = [port.value.node]
    }
  }
  
  # Volume mounts
  dynamic "volume" {
    for_each = var.volumes
    content {
      source      = volume.value.source
      destination = volume.value.destination
      node_filters = volume.value.node_filters
    }
  }
  
  # Environment variables
  dynamic "env" {
    for_each = var.environment_variables
    content {
      key   = env.value.key
      value = env.value.value
    }
  }
  
  # Registry configuration
  dynamic "registry" {
    for_each = var.registries
    content {
      name = registry.value.name
      host = registry.value.host
      port = registry.value.port
    }
  }
  
  # Labels
  dynamic "label" {
    for_each = var.labels
    content {
      key          = label.value.key
      value        = label.value.value
      node_filters = label.value.node_filters
    }
  }
  
  # Network settings
  network = var.network_name
  
  # Timeout for cluster operations
  timeout = "${var.cluster_timeout}s"
  
  # K3s image
  image = var.k3s_image
}