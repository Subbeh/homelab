provider "ovh" {
  endpoint           = "ovh-ca"
  application_key    = var.OVH_APPLICATION_KEY
  application_secret = var.OVH_APPLICATION_SECRET
  consumer_key       = var.OVH_CONSUMER_KEY
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
} 