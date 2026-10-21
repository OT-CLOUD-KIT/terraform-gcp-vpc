terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = "us-central1"
}
variable "project_id" {
  type = string
}

module "vpc" {
  source       = "../.."
  project_id   = var.project_id
  network_name = "example-gke-network"
  subnets = [{
    subnet_name           = "gke-nodes"
    subnet_region         = "us-central1"
    subnet_cidr           = "10.10.0.0/20"
    subnet_private_access = true
    subnet_flow_logs      = true
  }]
  secondary_ranges = {
    "us-central1/gke-nodes" = [
      { range_name = "gke-pods", ip_cidr_range = "10.20.0.0/16" },
      { range_name = "gke-services", ip_cidr_range = "10.30.0.0/20" }
    ]
  }

}
output "network" {
  value = module.vpc.network_self_link
}
output "subnets" {
  value = module.vpc.subnets
}
