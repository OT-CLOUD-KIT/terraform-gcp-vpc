resource "google_compute_shared_vpc_host_project" "host" {
  count      = var.enable_shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [google_compute_network.network]
}
resource "google_compute_shared_vpc_service_project" "service" {
  for_each        = var.shared_vpc_service_projects
  host_project    = var.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.host]
}
resource "google_compute_subnetwork_iam_member" "network_user" {
  for_each   = var.subnet_iam_members
  project    = var.project_id
  region     = try(local.subnets[each.value.subnet_key].subnet_region, null)
  subnetwork = try(google_compute_subnetwork.subnetwork[each.value.subnet_key].name, null)
  role       = "roles/compute.networkUser"
  member     = each.value.member
  depends_on = [google_compute_shared_vpc_service_project.service]
}
