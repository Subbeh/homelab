provider "proxmox" {
  pm_api_url          = "https://${var.pm_host}:8006/api2/json"
  pm_api_token_id     = data.sops_file.pve_secrets.data["pm_api_token_id"]
  pm_api_token_secret = data.sops_file.pve_secrets.data["pm_api_token_secret"]
  pm_tls_insecure     = true
  pm_parallel         = 2
  pm_timeout          = 600
  pm_debug            = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default          = "debug"
    _capturelog       = ""
  }
}

data "sops_file" "pve_secrets" {
  source_file = "pve.sops.yaml"
}
