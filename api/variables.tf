variable "LEARNING_GITHUB_CALLBACK" {
  description = "GitHub callback URL for learning app"
}

variable "LEARN_OPS_OAUTH_CLIENT_ID" {
  description = "OAuth client ID for learning app"
}

variable "LEARN_OPS_OAUTH_SECRET_KEY" {
  description = "OAuth secret key for learning app"
  sensitive   = true
}

variable "LEARN_OPS_DJANGO_SECRET_KEY" {
  description = "Django secret key for learning app"
  sensitive   = true
}

variable "LEARN_OPS_ALLOWED_HOSTS" {
  description = "Allowed hosts for learning app"
}

variable "LEARN_OPS_SUPERUSER_NAME" {
  description = "Superuser name for learning app"
}

variable "LEARN_OPS_SUPERUSER_PASSWORD" {
  description = "Superuser password for learning app"
  sensitive   = true
}

variable "SLACK_TOKEN" {
  description = "Slack token for learning app"
  sensitive   = true
}
