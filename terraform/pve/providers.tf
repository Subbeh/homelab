terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.4.0"
    }
  }
}

module "env" {
  source = "../../modules/env"
}

provider "doppler" {
  doppler_token = module.env.doppler_token
}

provider "proxmox" {
  pm_api_url      = "https://pve-nuc-01:8006/api2/json"
  # pm_api_token_id     = module.env.pm_api_token_id
  # pm_api_token_secret = module.env.pm_api_token_secret
  pm_user         = module.env.pm_user
  pm_password     = module.env.pm_password
  pm_tls_insecure = true
  pm_parallel     = 2
  pm_debug        = true
  pm_log_enable   = true
  pm_log_file     = "terraform-plugin-proxmox.log"
}

