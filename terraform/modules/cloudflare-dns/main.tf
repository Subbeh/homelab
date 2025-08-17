terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "domain" {
  name = var.domain_name
}

resource "cloudflare_record" "ipv4" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.subdomain
  content = var.ipv4_address
  type    = "A"
  proxied = var.enable_proxy
  ttl     = var.enable_proxy ? 1 : 3600
} 