terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token  # This will be provided via terraform.tfvars
}

# Reference existing SSH key
data "digitalocean_ssh_key" "github_actions" {
  name = "digitalocean"  # The name of your existing key in DO
}

# Reference an existing project
data "digitalocean_project" "learningplatform" {
  name = "Learning Platform"
}

# Valkey droplet
resource "digitalocean_droplet" "valkey" {
  name     = "valkey"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-22-04-x64"
  region   = var.region
  ssh_keys = [data.digitalocean_ssh_key.github_actions.fingerprint]

  user_data = <<-EOF
#!/bin/bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Create directory for Valkey
mkdir -p /opt/valkey

# Create Docker Compose file
cat > /opt/valkey/docker-compose.yml <<'COMPOSE'
services:
  valkey:
    image: valkey/valkey:latest
    ports:
      - "6379:6379"
    volumes:
      - valkey-data:/data
    restart: unless-stopped

volumes:
  valkey-data:
COMPOSE

# Start Valkey service
cd /opt/valkey
docker compose up -d
              EOF
}

# Monarch droplet
resource "digitalocean_droplet" "monarch" {
  name     = "monarch"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-22-04-x64"
  region   = var.region
  ssh_keys = [data.digitalocean_ssh_key.github_actions.fingerprint]
}

# Firewall rules (port 6379 is correct)
resource "digitalocean_firewall" "valkey" {
  name = "valkey-firewall"

  droplet_ids = [digitalocean_droplet.valkey.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6379"
    source_droplet_ids = [
      digitalocean_droplet.monarch.id,
      var.api_droplet_id
    ]
  }
}

resource "digitalocean_project_resources" "learningplatform_resources" {
  project = data.digitalocean_project.learningplatform.id
  resources = [
    digitalocean_droplet.valkey.urn,
    digitalocean_droplet.monarch.urn
  ]
}