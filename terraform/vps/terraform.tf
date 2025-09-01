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
      version = "~> 2.7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
} 

