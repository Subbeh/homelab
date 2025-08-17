variable "OVH_APPLICATION_KEY" {
  description = "OVH API Application Key"
  type        = string
  sensitive   = true
}

variable "OVH_APPLICATION_SECRET" {
  description = "OVH API Application Secret"
  type        = string
  sensitive   = true
}

variable "OVH_CONSUMER_KEY" {
  description = "OVH API Consumer Key"
  type        = string
  sensitive   = true
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "vps_service_name" {
  description = "OVH VPS service name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the VPS"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the VPS"
  type        = string
} 