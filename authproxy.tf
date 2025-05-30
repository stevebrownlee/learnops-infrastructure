resource "digitalocean_droplet" "authproxy" {
  name     = "authproxy"
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

    # Install certbot for certificate generation
    sudo apt-get install certbot -y

    # Create directory for certificates
    sudo mkdir -p /etc/letsencrypt
    sudo mkdir -p /var/lib/letsencrypt

    # Create directory for cert challenge responses
    sudo mkdir -p /var/www/certbot

    # Obtain initial certificate using webroot mode
    # First, we need to start a temporary web server for the initial certificate
    sudo certbot certonly --standalone \
      --non-interactive --agree-tos \
      --email ${var.ssl_cert_email} \
      --domains authproxy.nss.team \
      --preferred-challenges http

    # Set permissions to allow container to read certs
    sudo chmod -R 755 /etc/letsencrypt

    # Set up auto-renewal using webroot method (will work after container is deployed)
    echo "0 3 * * * certbot renew --quiet --webroot --webroot-path /var/www/certbot --deploy-hook 'cd /opt/authproxy && docker compose restart authproxy'" | sudo tee -a /var/spool/cron/crontabs/root

    # Create directory for Auth Proxy
    mkdir -p /opt/authproxy

    # Create a flag file to indicate setup is complete
    touch /opt/setup_complete
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
    port_range = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow HTTPS (for SSL)
  inbound_rule {
    protocol = "tcp"
    port_range = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow direct access on 3000 as well (if needed)
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

resource "digitalocean_record" "authproxy" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "authproxy"
  value  = digitalocean_droplet.authproxy.ipv4_address
  ttl    = 300
}