# Learning Platform Infrastructure

## Getting Started

1. Create a `terraform.tfvars` file in the project directory
2. Add the following content
  ```env
  DIGITAL_OCEAN_TOKEN = "dop_v1_placeholder_personal_access_token"
  REGION = "nyc1"
  API_DROPLET_ID = "111111111"
  SSL_CERT_EMAIL = "you@domain.com"
  ```
3. Log into the Digital Ocean platform dashboard
4. Click **API** option in left-nav
5. Generate a new personal access token
6. Paste your new token as the value of **DIGITAL_OCEAN_TOKEN**
7. Go to the **Droplets** section in the left-nav
8. Click on the Droplet that is running API container
9. In the URL, copy the numerical ID of the droplet after the `/droplets` section of the URL
10. Paste that as the value of the **API_DROPLET_ID** variable
11. Add your preferred email for the value of **SSL_CERT_EMAIL**

## System Diagram

```mermaid
graph TB
    subgraph "Learning Platform Infrastructure"
        subgraph "Domain: nss.team"
            switchboard["switchboard.nss.team
            (DNS A Record)"]
            monarch["monarch.nss.team
            (DNS A Record)"]
            authproxy["authproxy.nss.team
            (DNS A Record)"]
        end

        subgraph "Droplets"
            vd["Valkey Droplet
            s-1vcpu-1gb
            Ubuntu 22.04"]
            md["Monarch Droplet
            s-1vcpu-1gb
            Ubuntu 22.04"]
            apd["Auth Proxy Droplet
            s-1vcpu-1gb
            Ubuntu 22.04"]
            api["API Droplet
            (Existing)"]
        end

        subgraph "Firewalls"
            vf["Valkey Firewall
            Inbound: 22, 6379
            Outbound: 80, 443, 53"]
            mf["Monarch Firewall
            Inbound: 22
            Outbound: 80, 443, 53, 6379"]
            apf["Auth Proxy Firewall
            Inbound: 22, 80, 443, 3000
            Outbound: 80, 443, 53"]
        end
    end

    %% Connections
    switchboard --> vd
    monarch --> md
    authproxy --> apd

    %% Service Communications
    md -->|"Valkey Protocol
    Port 6379"| vd
    api -->|"Valkey Protocol
    Port 6379"| vd

    %% Firewall Rules
    vf -.->|"Controls Access"| vd
    mf -.->|"Controls Access"| md
    apf -.->|"Controls Access"| apd

    classDef droplet fill:#b8e994,stroke:#333,stroke-width:2px
    classDef firewall fill:#f8c291,stroke:#333,stroke-width:2px
    classDef dns fill:#82ccdd,stroke:#333,stroke-width:2px

    class vd,md,api,apd droplet
    class vf,mf,apf firewall
    class switchboard,monarch,authproxy dns
```

If you are trying to build and deploy your own system, you will also need to modify the following terraform configurations.

```tf
data "digitalocean_domain" "default" {
  name = "nss.team"  # Change this to your TLD
}

resource "digitalocean_record" "valkey" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "switchboard"   # Change this to your preferred subdomain
  value  = digitalocean_droplet.valkey.ipv4_address
  ttl    = 300
}

resource "digitalocean_record" "monarch" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "monarch"       # Change this to your preferred subdomain
  value  = digitalocean_droplet.monarch.ipv4_address
  ttl    = 300
}

resource "digitalocean_record" "authproxy" {
  domain = data.digitalocean_domain.default.id
  type   = "A"
  name   = "authproxy"     # Change this to your preferred subdomain
  value  = digitalocean_droplet.authproxy.ipv4_address
  ttl    = 300
}
```

## SSL Certificate Configuration

The Auth Proxy droplet is configured to automatically obtain and renew SSL certificates using Certbot. You'll need to provide an email address for certificate notifications:

```tf
variable "ssl_cert_email" {
  description = "Email address to use for certbot-created certificates"
  type        = string
}
```

This email will be used for important notifications about certificate expiration and renewal. The certificates are automatically obtained during the initial setup and a cron job is configured for automatic renewal.

Save the `terraform.tfvars.example` file as a new `terraform.tfvars` file and update the variables with the values that you want.