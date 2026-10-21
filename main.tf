resource "google_compute_network" "network" {
  name                            = var.network_name
  description                     = var.description
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  mtu                             = var.mtu == 0 ? null : var.mtu
  project                         = var.project_id
  delete_default_routes_on_create = var.delete_default_internet_gateway_routes

  lifecycle {
    precondition {
      condition     = alltrue([for key in keys(var.secondary_ranges) : contains(keys(local.subnets), key) || contains(local.subnet_names, key)])
      error_message = "Every secondary_ranges key must identify a declared subnet."
    }
    precondition {
      condition     = alltrue([for key, s in local.subnets : !(contains(keys(var.secondary_ranges), key) && contains(keys(var.secondary_ranges), s.subnet_name))])
      error_message = "Supply either region/name or name secondary ranges for a subnet, not both."
    }
    precondition {
      condition = alltrue([for name in local.subnet_names : !contains(keys(var.secondary_ranges), name) || length([
        for s in var.subnets : s if s.subnet_name == name
      ]) == 1])
      error_message = "Repeated subnet names across regions require region/name secondary-range keys."
    }
    precondition {
      condition     = var.enable_shared_vpc_host || length(var.shared_vpc_service_projects) == 0
      error_message = "Service project attachments require enable_shared_vpc_host=true."
    }
    precondition {
      condition     = !contains(var.shared_vpc_service_projects, var.project_id)
      error_message = "The host project cannot also be a service project."
    }
    precondition {
      condition     = alltrue([for binding in values(var.subnet_iam_members) : contains(keys(local.subnets), binding.subnet_key)])
      error_message = "Each subnet IAM binding must reference an existing region/subnet_name key."
    }
  }
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each                   = local.subnets
  name                       = each.value.subnet_name
  network                    = google_compute_network.network.id
  project                    = var.project_id
  description                = each.value.description
  ip_cidr_range              = each.value.subnet_cidr
  region                     = each.value.subnet_region
  private_ip_google_access   = each.value.subnet_private_access
  private_ipv6_google_access = replace(coalesce(each.value.private_ipv6_google_access, each.value.private_ipv6_google_acces, "DISABLE_GOOGLE_ACCESS"), "false", "DISABLE_GOOGLE_ACCESS")
  purpose                    = each.value.purpose
  role                       = contains(local.proxy_purposes, coalesce(each.value.purpose, "PRIVATE")) ? coalesce(each.value.role, "ACTIVE") : null

  dynamic "log_config" {
    for_each = each.value.subnet_flow_logs ? [each.value] : []
    content {
      aggregation_interval = log_config.value.subnet_flow_logs_interval
      flow_sampling        = log_config.value.subnet_flow_logs_sampling
      metadata             = log_config.value.subnet_flow_logs_metadata
    }
  }

  # Use a nested block for every GKE pod/service secondary range.
  # An empty collection removes managed ranges from configuration, so review the
  # resulting plan carefully before applying to an existing GKE subnet.
  dynamic "secondary_ip_range" {
    for_each = local.subnet_secondary_ranges[each.key]
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  lifecycle {
    precondition {
      condition     = !contains(local.proxy_purposes, coalesce(each.value.purpose, "PRIVATE")) || (!each.value.subnet_flow_logs && !each.value.subnet_private_access && length(local.subnet_secondary_ranges[each.key]) == 0)
      error_message = "Proxy-only subnets must disable flow logs/private Google access and have no secondary ranges."
    }
    precondition {
      condition     = each.value.role == null || contains(local.proxy_purposes, coalesce(each.value.purpose, "PRIVATE"))
      error_message = "role is only supported here for proxy-only subnet purposes."
    }
  }
}
