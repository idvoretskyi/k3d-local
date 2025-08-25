# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = var.monitoring_namespace

    labels = {
      name                                 = var.monitoring_namespace
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }

  depends_on = [null_resource.cluster_ready]
}

# kube-prometheus-stack Helm chart
resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_monitoring ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  # Wait for the release to be deployed
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "local-path"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          # Resource requests and limits
          resources = var.prometheus_resources
        }

        # Service configuration for external access
        service = {
          type = "ClusterIP"
          port = 9090
        }

        # Ingress configuration
        ingress = var.prometheus_ingress
      }

      # Alertmanager configuration
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "local-path"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }
          # Resource requests and limits
          resources = var.alertmanager_resources
        }

        # Service configuration
        service = {
          type = "ClusterIP"
          port = 9093
        }

        # Ingress configuration
        ingress = var.alertmanager_ingress
      }

      # Grafana configuration
      grafana = {
        # Admin credentials
        adminPassword = var.grafana_admin_password

        # Persistence
        persistence = {
          enabled          = true
          storageClassName = "local-path"
          size             = var.grafana_storage_size
        }

        # Resource requests and limits
        resources = var.grafana_resources

        # Service configuration
        service = {
          type = "ClusterIP"
          port = 80
        }

        # Ingress configuration
        ingress = var.grafana_ingress

        # Additional datasources
        additionalDataSources = var.grafana_additional_datasources

        # Dashboard providers
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                orgId           = 1
                folder          = ""
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        # Sidecar configuration for dashboards
        sidecar = {
          dashboards = {
            enabled = true
            label   = "grafana_dashboard"
            folder  = "/var/lib/grafana/dashboards"
          }
          datasources = {
            enabled = true
            label   = "grafana_datasource"
          }
        }
      }

      # Node Exporter configuration
      nodeExporter = {
        enabled = var.enable_node_exporter
      }

      # Kube State Metrics configuration
      kubeStateMetrics = {
        enabled = var.enable_kube_state_metrics
      }

      # CoreDNS monitoring
      coreDns = {
        enabled = true
      }

      # Kubelet monitoring
      kubelet = {
        enabled = true
      }

      # kubeApiServer monitoring
      kubeApiServer = {
        enabled = true
      }

      # kubeControllerManager monitoring
      kubeControllerManager = {
        enabled = true
      }

      # kubeScheduler monitoring
      kubeScheduler = {
        enabled = true
      }

      # kubeProxy monitoring
      kubeProxy = {
        enabled = true
      }

      # etcd monitoring
      kubeEtcd = {
        enabled = true
      }
    })
  ]

  # Custom values override
  dynamic "set" {
    for_each = var.kube_prometheus_stack_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Create LoadBalancer services for external access if enabled
resource "kubernetes_service" "grafana_loadbalancer" {
  count = var.enable_monitoring && var.enable_grafana_loadbalancer ? 1 : 0

  metadata {
    name      = "grafana-loadbalancer"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name

    labels = {
      app = "grafana-loadbalancer"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "grafana"
      "app.kubernetes.io/instance" = "kube-prometheus-stack"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "kubernetes_service" "prometheus_loadbalancer" {
  count = var.enable_monitoring && var.enable_prometheus_loadbalancer ? 1 : 0

  metadata {
    name      = "prometheus-loadbalancer"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name

    labels = {
      app = "prometheus-loadbalancer"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "prometheus"
      "app.kubernetes.io/instance" = "kube-prometheus-stack"
    }

    port {
      name        = "http"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "kubernetes_service" "alertmanager_loadbalancer" {
  count = var.enable_monitoring && var.enable_alertmanager_loadbalancer ? 1 : 0

  metadata {
    name      = "alertmanager-loadbalancer"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name

    labels = {
      app = "alertmanager-loadbalancer"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "alertmanager"
      "app.kubernetes.io/instance" = "kube-prometheus-stack"
    }

    port {
      name        = "http"
      port        = 9093
      target_port = 9093
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}