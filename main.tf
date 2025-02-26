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
  sudo apt-get update -y
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y

  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

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

  user_data = <<-EOF
              #!/bin/bash

              # Install Docker
              sudo apt-get update -y
              sudo apt-get install ca-certificates curl -y
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y

              sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

              # Create deployment directory
              mkdir -p /opt/monarch

              # Create flag file to indicate setup is complete
              touch /opt/setup_complete
              EOF
}

resource "digitalocean_droplet" "authproxy" {
  name     = "authproxy"
  size     = "s-1vcpu-1gb"  # Smallest size should be sufficient for a proxy service
  image    = "ubuntu-22-04-x64"
  region   = var.region
  ssh_keys = [data.digitalocean_ssh_key.github_actions.fingerprint]

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo apt-get update -y
              sudo apt-get install ca-certificates curl -y
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y

              sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

              # Create directory for Auth Proxy
              mkdir -p /opt/authproxy

              # Create Docker Compose file
              cat > /opt/authproxy/docker-compose.yml <<'COMPOSE'
              services:
                authproxy:
                  image: ${var.docker_registry}/auth-proxy:latest
                  ports:
                    - "3000:3000"
                  environment:
                    - PORT=3000
                    - OAUTH_CLIENT_ID=${var.foundations_client_id}
                    - OAUTH_CLIENT_SECRET=${var.foundations_client_secret}
                    - ALLOWED_ORIGINS=${var.proxy_allowed_origins}
                  restart: unless-stopped
              COMPOSE

              # Create .env file for environment variables
              cat > /opt/authproxy/.env <<'ENV'
              OAUTH_CLIENT_ID=${var.foundations_client_id}
              OAUTH_CLIENT_SECRET=${var.foundations_client_secret}
              ALLOWED_ORIGINS=${var.proxy_allowed_origins}
              ENV

              # Create deploy script
              cat > /opt/authproxy/deploy.sh <<'SCRIPT'
              #!/bin/bash
              cd /opt/authproxy
              docker login ${var.docker_registry} -u ${var.do_username} -p ${var.do_token}
              docker pull ${var.docker_registry}/auth-proxy:latest
              docker compose pull
              docker compose up -d
              SCRIPT

              chmod +x /opt/authproxy/deploy.sh

              # Run initial deployment
              /opt/authproxy/deploy.sh
              EOF
}

resource "digitalocean_firewall" "authproxy" {
  name = "authproxy-firewall"
  droplet_ids = [digitalocean_droplet.authproxy.id]

  # Allow SSH
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow HTTP (for the proxy service)
  inbound_rule {
    protocol = "tcp"
    port_range = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Add outbound rules
  outbound_rule {
    protocol = "tcp"
    port_range = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "valkey" {
  name = "valkey-firewall"
  droplet_ids = [digitalocean_droplet.valkey.id]

  # Allow SSH
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }


  inbound_rule {
    protocol = "tcp"
    port_range = "6379"
    source_droplet_ids = [
      digitalocean_droplet.monarch.id,
      var.api_droplet_id
    ]
  }

  # Add outbound rules
  outbound_rule {
    protocol = "tcp"
    port_range = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Add firewall for monarch droplet too
resource "digitalocean_firewall" "monarch" {
  name = "monarch-firewall"
  droplet_ids = [digitalocean_droplet.monarch.id]

  # Allow SSH
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Add outbound rules
  outbound_rule {
    protocol = "tcp"
    port_range = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "6379"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_record" "valkey" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "switchboard"
  value  = digitalocean_droplet.valkey.ipv4_address
  ttl    = 300
}

resource "digitalocean_record" "monarch" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "monarch"
  value  = digitalocean_droplet.monarch.ipv4_address
  ttl    = 300
}

resource "digitalocean_record" "authproxy" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "authproxy"
  value  = digitalocean_droplet.authproxy.ipv4_address
  ttl    = 300
}

resource "digitalocean_project_resources" "learningplatform_resources" {
  project = data.digitalocean_project.learningplatform.id
  resources = [
    digitalocean_droplet.valkey.urn,
    digitalocean_droplet.authproxy.urn,
    digitalocean_droplet.monarch.urn
  ]
}