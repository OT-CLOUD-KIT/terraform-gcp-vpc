variable "project_id" {
  type        = string
  description = "The project ID to host the network in"
}

variable "region" {
  type        = string
  description = "The region to use"
}

variable "main_zone" {
  type        = string
  description = "The zone to use as primary"
}

variable "credentials_file_path" {
  type        = string
  description = "The credentials JSON file used to authenticate with GCP"
}

variable "compute_route_name" {
  type        = string
  description = "The name of the compute route"
}

variable "subnet_ip_cidr_range" {
  type        = string
  description = "The IP CIDR Range of the Subnetwork"
}

variable "compute_route_dest_range" {
  type        = string
  description = "The destsination range of the Compute Route"
}