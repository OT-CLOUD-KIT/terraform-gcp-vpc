output "network_id" {
  description = "VPC resource ID."
  value       = google_compute_network.network.id
}
output "network_name" {
  description = "VPC name."
  value       = google_compute_network.network.name
}
output "network_self_link" {
  description = "VPC self link."
  value       = google_compute_network.network.self_link
}
output "subnets" {
  description = "Subnet integration outputs keyed by region/name."
  value = { for key, s in google_compute_subnetwork.subnetwork : key => {
    id                    = s.id
    name                  = s.name
    self_link             = s.self_link
    region                = s.region
    ip_cidr_range         = s.ip_cidr_range
    private_google_access = s.private_ip_google_access
    secondary_ranges      = { for r in local.subnet_secondary_ranges[key] : r.range_name => r.ip_cidr_range }
  } }
}
output "shared_vpc_host_project_id" {
  description = "Managed Shared VPC host project ID, or null when disabled."
  value       = var.enable_shared_vpc_host ? google_compute_shared_vpc_host_project.host[0].project : null
}
output "shared_vpc_service_project_ids" {
  description = "Service project IDs managed by this module."
  value       = sort([for p in google_compute_shared_vpc_service_project.service : p.service_project])
}
