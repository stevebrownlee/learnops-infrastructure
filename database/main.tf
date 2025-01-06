resource "digitalocean_database_cluster" "postgres_db" {
  name       = "postgres-cluster"
  engine     = "pg"
  version    = "14"
  size       = "db-s-1vcpu-2gb"
  region     = "nyc3"
  node_count = 1  // This sets up a single node cluster, increase this number for a multi-node setup
}

resource "digitalocean_database_db" "learning_db" {
  cluster_id = digitalocean_database_cluster.postgres_db.id
  name       = "${var.LEARN_OPS_DB}"
}

resource "digitalocean_database_user" "database_user" {
  cluster_id = digitalocean_database_cluster.postgres_db.id
  name       = "${var.LEARN_OPS_DB_USER}"
}

resource "digitalocean_database_firewall" "database_firewall" {
  cluster_id = digitalocean_database_cluster.postgres_db.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.www-1.id
  }
}
