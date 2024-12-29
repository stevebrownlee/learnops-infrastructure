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
