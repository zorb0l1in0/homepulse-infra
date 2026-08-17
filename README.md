# HomePulse — Remote Property Monitoring Platform

Infrastructure-as-Code project for monitoring remote properties (temperature, humidity, intrusion). Built with **Terraform**, **Ansible**, **Docker**, and **AWS**, with CI/CD via **GitHub Actions**.

## Architecture

```
Sensor Simulator (Python)
  → MQTT (Mosquitto)
    → Telegraf
      → InfluxDB
        → Grafana (dashboards + Telegram alerts)
          → ALB + HTTPS (external access)
```

All services containerized with Docker on a single EC2 instance. Networking and infrastructure managed via Terraform (VPC, subnets, security groups, ALB). Server configuration automated with Ansible.

## Tech Stack

| Layer | Tools |
|---|---|
| Infrastructure | Terraform, AWS (VPC, EC2, ALB, ACM, S3) |
| Configuration | Ansible (roles: common, docker, mosquitto, monitoring) |
| Containers | Docker, Docker Compose |
| Data pipeline | Mosquitto (MQTT) → Telegraf → InfluxDB |
| Visualization | Grafana (provisioned as code, JSON dashboards) |
| Alerting | Grafana → Telegram |
| CI/CD | GitHub Actions (plan → approve → apply → ansible-playbook) |
| Sensor simulation | Python (fake sensor data for Torino and Tenerife properties) |

## AWS Infrastructure

```
┌─────────────────────────────────────────────────────┐
│ VPC 10.0.0.0/16                                     │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ Public Subnet 10.0.1.0/24 (eu-west-1a)     │   │
│   │                                             │   │
│   │   ┌─────────────────────────────────────┐   │   │
│   │   │ EC2 t3.micro (Ubuntu 24.04)         │   │   │
│   │   │                                     │   │   │
│   │   │  Docker containers:                 │   │   │
│   │   │  ├── Mosquitto (MQTT broker)        │   │   │
│   │   │  ├── Telegraf (metrics collector)   │   │   │
│   │   │  ├── InfluxDB (time-series DB)      │   │   │
│   │   │  ├── Grafana (dashboards)           │   │   │
│   │   │  └── Sensor simulator (Python)      │   │   │
│   │   └─────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
│   Internet Gateway ←→ Route Table ←→ Subnet         │
│   Security Group: SSH(22), Grafana(3000), HTTPS(443)│
└─────────────────────────────────────────────────────┘
```

## Project Structure

```
homepulse-infra/
├── main.tf                  # Terraform resources (VPC, subnet, EC2, SG, IGW)
├── variables.tf             # Input variables
├── outputs.tf               # Outputs (IPs, IDs, SSH command)
├── example.tfvars           # Example variable values
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── site.yml             # Main playbook
│   ├── inventories/
│   │   └── hosts.ini        # EC2 inventory (from Terraform output)
│   ├── group_vars/
│   │   └── homepulse.yml    # Group variables
│   └── roles/
│       ├── common/          # Base packages, timezone, firewall
│       ├── docker/          # Docker CE + Compose installation
│       ├── mosquitto/       # MQTT broker configuration
│       └── monitoring/      # Telegraf + InfluxDB + Grafana stack
├── .gitignore
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.15
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with `aws configure`
- Git

## Quick Start

### 1. Provision infrastructure

```bash
terraform init
terraform plan -var="my_ip=$(curl -s ifconfig.me)/32"
terraform apply -var="my_ip=$(curl -s ifconfig.me)/32"
```

### 2. Configure server

```bash
cd ansible
ansible-playbook site.yml
```

### 3. Access services

```bash
# SSH into the server
ssh -i homepulse-key.pem ubuntu@<EC2_PUBLIC_IP>

# Grafana dashboard
http://<EC2_PUBLIC_IP>:3000
```

### 4. Tear down

```bash
terraform destroy -var="my_ip=$(curl -s ifconfig.me)/32"
```

## Project Phases

- [x] Phase 1 — Terraform setup + VPC
- [x] Phase 2 — Networking (subnet, IGW, route table, security group)
- [x] Phase 3 — EC2 instance with SSH key pair
- [X] Phase 4 — Ansible roles (common, docker, mosquitto, monitoring)
- [X] Phase 5 — Sensor simulator (Python → MQTT)
- [ ] Phase 6 — Grafana dashboards + Telegram alerting
- [ ] Phase 7 — ALB + HTTPS (ACM certificate)
- [ ] Phase 8 — GitHub Actions CI/CD (plan → approve → apply → configure)
- [ ] Phase 9 — Multi-environment + Terraform modules (dev/prod)
- [ ] Phase 10 — (Future) Kafka for multi-property scale

## Cost Management

This project uses `t3.micro` (free tier eligible for 750 hrs/month in year one) and minimal AWS resources. The VPC, subnet, IGW, route table, and security group are free. Always run `terraform destroy` when not actively working to avoid charges.

## Security

- SSH and Grafana access restricted to your IP only via security group
- SSH key generated by Terraform, private key excluded from Git
- AWS credentials managed via `aws configure` (never committed)
- Ansible Vault used for secrets (Grafana admin password, Telegram bot token)