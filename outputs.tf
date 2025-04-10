output "valkey_ipv4" {
  description = "The public IPv4 address of the Valkey droplet"
  value       = digitalocean_droplet.valkey.ipv4_address
}

output "monarch_ipv4" {
  description = "The public IPv4 address of the Monarch droplet"
  value       = digitalocean_droplet.monarch.ipv4_address
}

output "authproxy_ipv4" {
  description = "The public IPv4 address of the Auth Proxy droplet"
  value       = digitalocean_droplet.authproxy.ipv4_address
}

output "valkey_fqdn" {
  description = "The fully qualified domain name for the Valkey service"
  value       = "switchboard.nss.team"
}

output "monarch_fqdn" {
  description = "The fully qualified domain name for the Monarch service"
  value       = "monarch.nss.team"
}

output "authproxy_fqdn" {
  description = "The fully qualified domain name for the Auth Proxy service"
  value       = "authproxy.nss.team"
}