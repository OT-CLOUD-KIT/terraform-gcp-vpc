variable "project_id" {
  type        = string
  description = "Existing project ID in which the network is managed."
}
variable "network_name" {
  type        = string
  description = "VPC network name."
}
variable "description" {
  type        = string
  default     = ""
  description = "Network description; review replacement behavior before changing."
}
variable "routing_mode" {
  type        = string
  default     = "GLOBAL"
  description = "Dynamic routing mode."
  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "routing_mode must be GLOBAL or REGIONAL."
  }
}
variable "auto_create_subnetworks" {
  type        = bool
  default     = false
  description = "Retained legacy option; use false for explicit GKE subnets."
}
variable "delete_default_internet_gateway_routes" {
  type        = bool
  default     = false
  description = "Delete default internet gateway routes when creating the network."
}
variable "mtu" {
  type        = number
  default     = 0
  description = "0 leaves the MTU unset; otherwise use an approved value from 1300 to 8896."
  validation {
    condition     = var.mtu == 0 || (var.mtu >= 1300 && var.mtu <= 8896 && floor(var.mtu) == var.mtu)
    error_message = "mtu must be 0 or an integer from 1300 to 8896."
  }
}
variable "subnets" {
  description = "Subnets keyed internally by region/name. Legacy string booleans/numbers are converted by Terraform."
  type = list(object({
    subnet_name                = string
    subnet_region              = string
    subnet_cidr                = string
    description                = optional(string)
    subnet_private_access      = optional(bool, false)
    private_ipv6_google_access = optional(string)
    private_ipv6_google_acces  = optional(string) # Legacy typo retained as an alias.
    subnet_flow_logs           = optional(bool, false)
    subnet_flow_logs_interval  = optional(string, "INTERVAL_5_SEC")
    subnet_flow_logs_sampling  = optional(number, 0.5)
    subnet_flow_logs_metadata  = optional(string, "INCLUDE_ALL_METADATA")
    purpose                    = optional(string)
    role                       = optional(string)
  }))
  default = []
  validation {
    condition     = length(distinct([for s in var.subnets : "${s.subnet_region}/${s.subnet_name}"])) == length(var.subnets)
    error_message = "Each region/subnet_name must be unique."
  }
  validation {
    condition     = alltrue([for s in var.subnets : can(cidrnetmask(s.subnet_cidr))])
    error_message = "Each subnet_cidr must be a valid IPv4 CIDR."
  }
  validation {
    condition     = alltrue([for s in var.subnets : s.subnet_flow_logs_sampling >= 0 && s.subnet_flow_logs_sampling <= 1])
    error_message = "Flow log sampling must be between 0 and 1."
  }
  validation {
    condition = alltrue([for s in var.subnets : contains([
      "DISABLE_GOOGLE_ACCESS", "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE", "ENABLE_BIDIRECTIONAL_ACCESS_TO_GOOGLE", "false"
    ], coalesce(s.private_ipv6_google_access, s.private_ipv6_google_acces, "DISABLE_GOOGLE_ACCESS"))])
    error_message = "Use a supported IPv6 Google Access enum; legacy false is accepted as disabled."
  }
}
variable "secondary_ranges" {
  type = map(list(object({
    range_name    = string
    ip_cidr_range = string
  })))
  default     = {}
  description = "Secondary ranges keyed by region/subnet_name (preferred) or legacy subnet_name. Do not supply both for one subnet."
  validation {
    condition = alltrue(flatten([for ranges in values(var.secondary_ranges) : [
      for r in ranges : can(cidrnetmask(r.ip_cidr_range)) && length(trimspace(r.range_name)) > 0
    ]]))
    error_message = "Secondary ranges require a nonempty name and valid IPv4 CIDR."
  }
  validation {
    condition     = alltrue([for ranges in values(var.secondary_ranges) : length(distinct([for r in ranges : r.range_name])) == length(ranges)])
    error_message = "Secondary range names must be unique within each subnet."
  }
}
variable "enable_shared_vpc_host" {
  type        = bool
  default     = false
  description = "Manage this project as a Shared VPC host. Configure once per host project, not once per VPC."
}
variable "shared_vpc_service_projects" {
  type        = set(string)
  default     = []
  description = "Existing service project IDs to attach to the managed Shared VPC host."
}
variable "subnet_iam_members" {
  type = map(object({
    subnet_key = string
    member     = string
  }))
  default     = {}
  description = "Stable binding key => region/subnet_name and principal; grants additive roles/compute.networkUser access."
}
