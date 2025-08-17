variable "domain_name" {
  description = "The domain name to manage DNS records for"
  type        = string
}

variable "subdomain" {
  description = "The subdomain to create"
  type        = string
}

variable "ipv4_address" {
  description = "The IPv4 address for the A record"
  type        = string
}

variable "enable_proxy" {
  description = "Whether to enable Cloudflare proxy (orange cloud)"
  type        = bool
  default     = false
} 