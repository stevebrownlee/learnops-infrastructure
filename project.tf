resource "digitalocean_project_resources" "learningplatform_resources" {
  project = data.digitalocean_project.learningplatform.id
  resources = [
    digitalocean_droplet.valkey.urn,
    digitalocean_droplet.authproxy.urn,
    digitalocean_droplet.monarch.urn
  ]
}