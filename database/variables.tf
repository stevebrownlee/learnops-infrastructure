variable "LEARN_OPS_DB" {
  description = "Database name for learning app"
}

variable "LEARN_OPS_DB_USER" {
  description = "Database user for learning app"
}

variable "LEARN_OPS_DB_PASSWORD" {
  description = "Database password for learning app"
  sensitive   = true
}

variable "LEARN_OPS_DB_HOST" {
  description = "Database host for learning app"
}

variable "LEARN_OPS_DB_PORT" {
  description = "Database port for learning app"
}

