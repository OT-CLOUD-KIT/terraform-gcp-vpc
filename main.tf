resource "google_compute_network" "network" {
  name                            = var.network_name
  description                     = var.description
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  mtu                             = var.mtu
  project                         = var.project_id
  delete_default_routes_on_create = var.delete_default_internet_gateway_routes
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each                   = local.subnets
  name                       = each.value.subnet_name
  network                    = var.network_name
  project                    = var.project_id
  description                = lookup(each.value, "description", null)
  ip_cidr_range              = each.value.subnet_cidr
  region                     = each.value.subnet_region
  private_ip_google_access   = lookup(each.value, "subnet_private_access", false)
  private_ipv6_google_access = lookup(each.value, "private_ipv6_google_acces", false)

  dynamic "log_config" {
    for_each = each.value.purpose == null ? lookup(each.value, "subnet_flow_logs", false) ? [{
      aggregation_interval = lookup(each.value, "subnet_flow_logs_interval", "INTERVAL_5_SEC")
      flow_sampling        = lookup(each.value, "subnet_flow_logs_sampling", "0.5")
      metadata             = lookup(each.value, "subnet_flow_logs_metadata", "INCLUDE_ALL_METADATA")
    }] : [] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
  secondary_ip_range = [
    for i in range(
      length(
        contains(
        keys(var.secondary_ranges), each.value.subnet_name) == true
        ? var.secondary_ranges[each.value.subnet_name]
        : []
    )) :
    var.secondary_ranges[each.value.subnet_name][i]
  ]
  purpose = lookup(each.value, "purpose", null)
  role    = each.value.purpose == "INTERNAL_HTTPS_LOAD_BALANCER" || each.value.purpose == "REGIONAL_MANAGED_PROXY" ? lookup(each.value, "role", "ACTIVE") : null
  depends_on = [
    google_compute_network.network
  ]
}