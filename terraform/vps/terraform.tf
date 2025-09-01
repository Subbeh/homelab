terraform {
  cloud {
    organization = "sbbh-cloud"

    workspaces {
      name = "vps"
    }
  }

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.51.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"
} 

