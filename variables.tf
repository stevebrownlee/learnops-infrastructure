variable "do_token" {
  description = "DigitalOcean API Token"
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  default     = "nyc1"
}

variable "api_droplet_id" {
  description = "ID of the API droplet"
  type        = string
}

variable "ssl_cert_email" {
  description = "Email address to use for certbot-created certificates"
  type        = string
}

# The following variables have been removed as they will be managed by GitHub Actions:
# - docker_registry
# - do_username
# - foundations_client_id
# - foundations_client_secret
# - proxy_allowed_origins
