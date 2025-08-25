locals {
  cluster_name = var.cluster_name

  # Build k3d command arguments
  port_mappings = concat([
    "--port=${var.http_port}:80@loadbalancer",
    "--port=${var.https_port}:443@loadbalancer"
    ], var.enable_monitoring ? [
    "--port=3000:3000@loadbalancer",
    "--port=9090:9090@loadbalancer",
    "--port=9093:9093@loadbalancer"
    ] : [], [
    for port in var.additional_ports :
    "--port=${port.host}:${port.container}@${join(",", port.node_filters)}"
  ])

  server_args = length(var.k3s_server_args) > 0 ? "--k3s-arg=${join(" --k3s-arg=", [for arg in var.k3s_server_args : "${arg}@server"])}" : ""
  agent_args  = length(var.k3s_agent_args) > 0 ? "--k3s-arg=${join(" --k3s-arg=", [for arg in var.k3s_agent_args : "${arg}@agent"])}" : ""

  volume_mounts = [
    for volume in var.volumes :
    "--volume=${volume.source}:${volume.destination}@${join(",", volume.node_filters)}"
  ]

  env_vars = [
    for env in var.environment_variables :
    "--env=${env.key}=${env.value}@all"
  ]
}

# Create k3d cluster using null_resource
resource "null_resource" "k3d_cluster" {
  # Trigger recreation when key variables change
  triggers = {
    cluster_name = var.cluster_name
    servers      = var.server_count
    agents       = var.agent_count
    ports        = join(",", local.port_mappings)
    monitoring   = var.enable_monitoring
  }

  # Create cluster
  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster create ${local.cluster_name} \
        --servers ${var.server_count} \
        --agents ${var.agent_count} \
        ${join(" ", local.port_mappings)} \
        ${length(local.volume_mounts) > 0 ? join(" ", local.volume_mounts) : ""} \
        ${length(local.env_vars) > 0 ? join(" ", local.env_vars) : ""} \
        ${local.server_args != "" ? local.server_args : ""} \
        ${local.agent_args != "" ? local.agent_args : ""} \
        --network ${var.network_name} \
        --image ${var.k3s_image} \
        --timeout ${var.cluster_timeout}s \
        --wait
    EOT

    # Set timeout for the command
    environment = {
      K3D_FIX_DNS = "1"
    }
  }

  # Destroy cluster
  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name} || true"
  }
}

# Wait for cluster to be ready
resource "null_resource" "cluster_ready" {
  depends_on = [null_resource.k3d_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for cluster to be accessible
      timeout 60s bash -c 'until kubectl --context=k3d-${local.cluster_name} cluster-info >/dev/null 2>&1; do sleep 2; done'
      
      # Wait for nodes to be ready
      kubectl --context=k3d-${local.cluster_name} wait --for=condition=Ready nodes --all --timeout=60s
    EOT
  }
}