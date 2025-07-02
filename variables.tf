variable "DIGITAL_OCEAN_TOKEN" {
  description = "DigitalOcean API Token"
  sensitive   = true
}

variable "REGION" {
  description = "DigitalOcean region"
  default     = "nyc1"
}

variable "API_DROPLET_ID" {
  description = "ID of the API droplet"
  type        = string
}

variable "SSL_CERT_EMAIL" {
  description = "Email address to use for certbot-created certificates"
  type        = string
}

# The following variables have been removed as they will be managed by GitHub Actions:
# - docker_registry
# - do_username
# - foundations_client_id
# - foundations_client_secret
# - proxy_allowed_origins
