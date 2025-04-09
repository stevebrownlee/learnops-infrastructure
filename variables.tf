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

variable "ssl_cert_email" {
  description = "Email address to use for certbot-created certificates"
  type        = string
}
