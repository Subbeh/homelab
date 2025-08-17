terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.51.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "ovh_vps" "vps" {
  service_name = var.vps_service_name
}

locals {
  ipv4 = [for ip in data.ovh_vps.vps.ips : ip if can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", ip))][0]
}

output "ipv4" {
  value = local.ipv4
}


module "cloudflare_dns" {
  source = "../modules/cloudflare-dns"

  domain_name  = var.domain_name
  subdomain    = var.subdomain
  ipv4_address = module.ovh_vps.ipv4
  enable_proxy = false
}
