# Valkey droplet
resource "digitalocean_droplet" "valkey" {
  name     = "valkey"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-22-04-x64"
  region   = var.REGION
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
      var.API_DROPLET_ID
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

resource "digitalocean_record" "valkey" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "switchboard"
  value  = digitalocean_droplet.valkey.ipv4_address
  ttl    = 300
}