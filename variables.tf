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

variable "docker_registry" {
  description = "Name of Digital Ocean Docker Registry"
  type        = string
}

variable "do_username" {
  description = "Name of Digital Ocean Docker Registry"
  type        = string
}

variable "foundations_client_id" {
  description = "Name of Digital Ocean Docker Registry"
  type        = string
}

variable "foundations_client_secret" {
  description = "Name of Digital Ocean Docker Registry"
  type        = string
}

variable "proxy_allowed_origins" {
  description = "Name of Digital Ocean Docker Registry"
  type        = string
}
