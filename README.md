# Learning Platform Infrastructure

```mermaid
graph TB
    subgraph "Digital Ocean Project: Learning Platform"
        subgraph "Domain: nss.team"
            switchboard["switchboard.nss.team\n(DNS A Record)"]
            monarch["monarch.nss.team\n(DNS A Record)"]
        end

        subgraph "Droplets"
            vd["Valkey Droplet\ns-1vcpu-1gb\nUbuntu 22.04"]
            md["Monarch Droplet\ns-1vcpu-1gb\nUbuntu 22.04"]
            api["API Droplet\n(Existing)"]
        end

        subgraph "Firewalls"
            vf["Valkey Firewall\nInbound: 22, 6379\nOutbound: 80, 443, 53"]
            mf["Monarch Firewall\nInbound: 22\nOutbound: 80, 443, 53, 6379"]
        end
    end

    %% Connections
    switchboard --> vd
    monarch --> md
    vf --> vd
    mf --> md

    %% Service Communications
    md -->|"Valkey Protocol\nPort 6379"| vd
    api -->|"Valkey Protocol\nPort 6379"| vd

    %% Firewall Rules
    vf -.->|"Controls Access"| vd
    mf -.->|"Controls Access"| md

    classDef droplet fill:#b8e994,stroke:#333,stroke-width:2px
    classDef firewall fill:#f8c291,stroke:#333,stroke-width:2px
    classDef dns fill:#82ccdd,stroke:#333,stroke-width:2px

    class vd,md,api droplet
    class vf,mf firewall
    class switchboard,monarch dns
```