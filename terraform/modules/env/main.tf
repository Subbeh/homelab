terraform {
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.4.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

data "sops_file" "env" {
  source_file = "${path.module}/../../env.sops.yaml"
}

data "doppler_secrets" "this" {}

locals {
  env = yamldecode(file("${path.module}/../../env.yaml"))
  pm_vars = nonsensitive(jsondecode(data.doppler_secrets.this.map.PVE_SECRETS))
  doppler_token = data.sops_file.env.data["DOPPLER_TOKEN"]
}
