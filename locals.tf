locals {
  subnets      = { for s in var.subnets : "${s.subnet_region}/${s.subnet_name}" => s }
  subnet_names = [for s in var.subnets : s.subnet_name]
  subnet_secondary_ranges = {
    for key, s in local.subnets : key => lookup(var.secondary_ranges, key, lookup(var.secondary_ranges, s.subnet_name, []))
  }
  proxy_purposes = ["INTERNAL_HTTPS_LOAD_BALANCER", "REGIONAL_MANAGED_PROXY", "GLOBAL_MANAGED_PROXY"]
}
