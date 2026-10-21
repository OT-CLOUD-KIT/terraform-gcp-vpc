# Terraform GCP VPC

This Terraform module provisions a custom Google Cloud VPC network and its subnets. It supports GKE Pod and Service secondary IP ranges, Private Google Access, VPC flow logs and optional Shared VPC configuration.

The module is designed to provide reusable networking for GKE, Compute Engine and other private Google Cloud workloads.

## Architecture

The module manages the following components:

- Custom mode VPC network
- Regional subnets
- GKE Pod and Service secondary IP ranges
- Private Google Access
- Optional VPC flow logs
- Optional Shared VPC host-project enablement
- Optional service-project attachments
- Additive subnet-level `roles/compute.networkUser` IAM membership

Cloud Router, Cloud NAT, VPN, Network Connectivity Center and firewall policies are outside this module.

## Providers

| Name | Source | Version |
|---|---|---|
| Google | `hashicorp/google` | `~> 7.0` |

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.7, < 2.0` |

## Resources

| Resource | Purpose |
|---|---|
| `google_compute_network.network` | Custom VPC network |
| `google_compute_subnetwork.subnetwork` | Regional subnets and secondary ranges |
| `google_compute_shared_vpc_host_project.host` | Optional Shared VPC host enablement |
| `google_compute_shared_vpc_service_project.service` | Optional service-project attachment |
| `google_compute_subnetwork_iam_member.network_user` | Additive subnet access for service-project principals |

## Usage

```hcl
module "vpc" {
  source = "./terraform-gcp-vpc"

  project_id   = "example-network-project"
  network_name = "platform-vpc"
  routing_mode = "GLOBAL"

  subnets = [{
    subnet_name           = "gke-nodes"
    subnet_region         = "us-central1"
    subnet_cidr           = "10.10.0.0/20"
    subnet_private_access = true
    subnet_flow_logs      = true
  }]

  secondary_ranges = {
    "us-central1/gke-nodes" = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "10.30.0.0/20"
      }
    ]
  }
}
```

Examples are available under `example/gke-network` and `example/shared-vpc`.

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `project_id` | Project in which the VPC is managed | `string` | required |
| `network_name` | VPC network name | `string` | required |
| `description` | Network description | `string` | empty |
| `routing_mode` | `GLOBAL` or `REGIONAL` dynamic routing | `string` | `GLOBAL` |
| `auto_create_subnetworks` | Enable automatic subnet creation | `bool` | `false` |
| `delete_default_internet_gateway_routes` | Remove default internet gateway routes | `bool` | `false` |
| `mtu` | Network MTU; zero leaves it unset | `number` | `0` |
| `subnets` | Regional subnet definitions | `list(object)` | `[]` |
| `secondary_ranges` | GKE Pod/Service ranges keyed by `region/subnet` | `map(list(object))` | `{}` |
| `enable_shared_vpc_host` | Enable the project as a Shared VPC host | `bool` | `false` |
| `shared_vpc_service_projects` | Service projects attached to the host | `set(string)` | `[]` |
| `subnet_iam_members` | Additive subnet Network User assignments | `map(object)` | `{}` |

### Subnet configuration

Each subnet requires `subnet_name`, `subnet_region` and `subnet_cidr`. Optional fields include:

| Field | Description | Default |
|---|---|---|
| `description` | Subnet description | `null` |
| `subnet_private_access` | Enable Private Google Access | `false` |
| `private_ipv6_google_access` | Private IPv6 Google access mode | disabled |
| `subnet_flow_logs` | Enable VPC flow logs | `false` |
| `subnet_flow_logs_interval` | Flow-log aggregation interval | `INTERVAL_5_SEC` |
| `subnet_flow_logs_sampling` | Flow-log sampling ratio | `0.5` |
| `subnet_flow_logs_metadata` | Flow-log metadata mode | `INCLUDE_ALL_METADATA` |
| `purpose` | Specialized subnet purpose | `null` |
| `role` | Proxy-only subnet role | `null` |

## Shared VPC

Set `enable_shared_vpc_host = true` to let this module manage host-project enablement. Supply service projects through `shared_vpc_service_projects` and grant individual service accounts or principals subnet access through `subnet_iam_members`.

Shared VPC host configuration should be owned by one Terraform state only. If another platform stack already manages it, keep the Shared VPC options disabled in this module.

## Outputs

| Name | Description |
|---|---|
| `network_id` | VPC resource ID |
| `network_name` | VPC network name |
| `network_self_link` | VPC network self-link |
| `subnets` | Subnet details keyed by region and name |
| `shared_vpc_host_project_id` | Managed host project ID when enabled |
| `shared_vpc_service_project_ids` | Service projects managed by this module |

## Important considerations

- Confirm that all primary and secondary CIDR ranges are non-overlapping before deployment.
- GKE must separately reference the Pod and Service range names in its IP allocation policy.
- Enable Private Google Access for private GKE nodes and other workloads that require Google APIs without external IP addresses.
- Review removal of secondary ranges or Shared VPC attachments carefully because it can disrupt existing workloads.
