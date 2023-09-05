terraform {
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.2.4"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}

data "sops_file" "env" {
  source_file = "${path.module}/../../env.sops.yaml"
}

data "doppler_secrets" "this" {}

locals {
  pm_vars = nonsensitive(jsondecode(data.doppler_secrets.this.map.PVE_SECRETS))
  doppler_token = data.sops_file.env.data["DOPPLER_TOKEN"]
}
