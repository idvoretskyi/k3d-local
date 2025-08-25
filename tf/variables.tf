variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "local-dev"
}

variable "server_count" {
  description = "Number of server nodes in the cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.server_count >= 1 && var.server_count <= 5
    error_message = "Server count must be between 1 and 5."
  }
}

variable "agent_count" {
  description = "Number of agent nodes in the cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.agent_count >= 0 && var.agent_count <= 10
    error_message = "Agent count must be between 0 and 10."
  }
}

variable "http_port" {
  description = "Host port for HTTP traffic (mapped to LoadBalancer port 80)"
  type        = number
  default     = 8080

  validation {
    condition     = var.http_port > 1024 && var.http_port < 65535
    error_message = "HTTP port must be between 1024 and 65535."
  }
}

variable "https_port" {
  description = "Host port for HTTPS traffic (mapped to LoadBalancer port 443)"
  type        = number
  default     = 8443

  validation {
    condition     = var.https_port > 1024 && var.https_port < 65535
    error_message = "HTTPS port must be between 1024 and 65535."
  }
}

variable "additional_ports" {
  description = "Additional port mappings for development services"
  type = list(object({
    host         = number
    container    = number
    node_filters = list(string)
  }))
  default = []
}

variable "k3s_server_args" {
  description = "Additional arguments for k3s server"
  type        = list(string)
  default = [
    "--disable=traefik",
    "--disable=servicelb"
  ]
}

variable "k3s_agent_args" {
  description = "Additional arguments for k3s agents"
  type        = list(string)
  default     = []
}

variable "k3s_image" {
  description = "K3s Docker image to use"
  type        = string
  default     = "rancher/k3s:latest"
}

variable "network_name" {
  description = "Docker network name for the cluster"
  type        = string
  default     = "k3d-local"
}

variable "volumes" {
  description = "Volume mounts for the cluster nodes"
  type = list(object({
    source       = string
    destination  = string
    node_filters = list(string)
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables for cluster nodes"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "registries" {
  description = "Container registries configuration"
  type = list(object({
    name = string
    host = string
    port = number
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to cluster nodes"
  type = list(object({
    key          = string
    value        = string
    node_filters = list(string)
  }))
  default = []
}

variable "cluster_timeout" {
  description = "Timeout for cluster operations (in seconds)"
  type        = number
  default     = 300

  validation {
    condition     = var.cluster_timeout >= 60 && var.cluster_timeout <= 1800
    error_message = "Cluster timeout must be between 60 and 1800 seconds."
  }
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable kube-prometheus-stack monitoring"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

# Prometheus Variables
variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "prometheus_resources" {
  description = "Resource requests and limits for Prometheus"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "512Mi"
      cpu    = "250m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }
}

variable "prometheus_ingress" {
  description = "Ingress configuration for Prometheus"
  type = object({
    enabled = bool
    hosts   = list(string)
  })
  default = {
    enabled = false
    hosts   = []
  }
}

variable "enable_prometheus_loadbalancer" {
  description = "Enable LoadBalancer service for Prometheus external access"
  type        = bool
  default     = true
}

# Alertmanager Variables
variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "2Gi"
}

variable "alertmanager_resources" {
  description = "Resource requests and limits for Alertmanager"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "128Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "512Mi"
      cpu    = "500m"
    }
  }
}

variable "alertmanager_ingress" {
  description = "Ingress configuration for Alertmanager"
  type = object({
    enabled = bool
    hosts   = list(string)
  })
  default = {
    enabled = false
    hosts   = []
  }
}

variable "enable_alertmanager_loadbalancer" {
  description = "Enable LoadBalancer service for Alertmanager external access"
  type        = bool
  default     = true
}

# Grafana Variables
variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "grafana_resources" {
  description = "Resource requests and limits for Grafana"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "256Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }
}

variable "grafana_ingress" {
  description = "Ingress configuration for Grafana"
  type = object({
    enabled = bool
    hosts   = list(string)
  })
  default = {
    enabled = false
    hosts   = []
  }
}

variable "grafana_additional_datasources" {
  description = "Additional datasources for Grafana"
  type        = list(map(any))
  default     = []
}

variable "enable_grafana_loadbalancer" {
  description = "Enable LoadBalancer service for Grafana external access"
  type        = bool
  default     = true
}

# Component Toggles
variable "enable_node_exporter" {
  description = "Enable Node Exporter for node metrics"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Enable Kube State Metrics"
  type        = bool
  default     = true
}

# Custom Helm Values
variable "kube_prometheus_stack_values" {
  description = "Additional Helm values for kube-prometheus-stack"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}