resource "digitalocean_droplet" "www-1" {
  name     = "www-1"
  region   = "nyc3"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-22-04-x64"
  ssh_keys = [
    data.digitalocean_ssh_key.digitalocean.id
  ]

  depends_on = [
    digitalocean_database_cluster.postgres_db
  ]
}

resource "digitalocean_record" "www" {
  domain = "nss.team"
  type   = "A"
  name   = "learning"
  value  = digitalocean_droplet.www-1.ipv4_address
}
