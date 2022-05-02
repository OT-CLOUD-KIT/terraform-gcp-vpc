# project_id = "bjbdevelopment"
project_id               = "terraform-gcp-123"
credentials_file_path    = "./service-account-credentials.json"
region                   = "asia-southeast2"
main_zone                = "asia-southeast2-a"
compute_route_name       = "egress-internet"
subnet_ip_cidr_range     = "10.10.0.0/16"
compute_route_dest_range = "0.0.0.0/0"