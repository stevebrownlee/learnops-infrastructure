data "digitalocean_domain" "default" {
  name = "nss.team"
}

# Reference existing SSH key
data "digitalocean_ssh_key" "github_actions" {
  name = "digitalocean"  # The name of your existing key in DO
}

# Reference an existing project
data "digitalocean_project" "learningplatform" {
  name = "Learning Platform"
}