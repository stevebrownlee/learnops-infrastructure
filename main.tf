# This file has been split into multiple files for better organization:
#
# - providers.tf: Contains the terraform block and provider configuration
# - data.tf: Contains all data sources (domain, SSH key, project)
# - valkey.tf: Contains the Valkey droplet, firewall, and DNS record
# - monarch.tf: Contains the Monarch droplet, firewall, and DNS record
# - authproxy.tf: Contains the Auth Proxy droplet, firewall, and DNS record
# - project.tf: Contains the project resources
# - outputs.tf: Contains output variables
#
# This modular structure makes the configuration easier to read, maintain, and extend.