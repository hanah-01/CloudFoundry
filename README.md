# DevOps Project

**Infrastructure as Code (IaC)** 

## Project Overview

This project demonstrates modern DevOps practices by building a complete cloud infrastructure using **Terraform**, **LocalStack**, and **Jenkins CI/CD**. It implements a serverless event-driven architecture

### Key Features

- **Infrastructure as Code** - Terraform for VPC, S3, Lambda, DynamoDB, EC2
- **Cloud Simulation** - LocalStack 
- **Serverless Pipeline** - Lambda processes artifacts and stores metadata in DynamoDB
- **CI/CD Automation** - Jenkins pipeline with security scanning (tfsec, Checkov)
- **Configuration Management** - Ansible playbooks for server setup
- **Security Best Practices** - S3 encryption, versioning, IAM least privilege

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      VPC (10.0.0.0/16)                  │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Public Subnet (10.0.1.0/24)                      │  │
│  │  ┌────────────┐              ┌────────────┐       │  │
│  │  │ EC2 Web    │              │  Security  │       │  │
│  │  │  Server    │────────────▶ │   Group    │       │  │
│  │  └────────────┘              └────────────┘       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                      ▲
                      │
                      │ Internet Gateway
                      │
         ┌────────────┼────────────────────────┐
         │            │                        │
    ┌────▼────┐  ┌───▼──────┐      ┌─────────▼────────┐
    │   S3    │  │  Lambda  │      │    DynamoDB       │
    │ Bucket  │─▶│ Function │─────▶│  Metadata Table   │
    └─────────┘  └──────────┘      └──────────────────┘
                                    (artifact_id, timestamp, env)
```

### Data Flow

1. **Artifact Upload** → S3 bucket (`/artifacts/` prefix)
2. **Event Trigger** → Lambda function invoked (S3 ObjectCreated event)
3. **Processing** → Lambda parses event, generates UUID
4. **Storage** → Metadata written to DynamoDB with timestamp
5. **Query** → DynamoDB GSI allows environment-based queries

---

## Project Structure

```
DevOps-Project/
├── README.md                    # This file
├── TESTING.md                   # Complete testing guide
├── payload.json                 # Lambda test event
│
├── terraform/                   # Infrastructure as Code
│   ├── providers.tf             # AWS + LocalStack configuration
│   ├── vpc.tf                   # Network infrastructure
│   ├── s3.tf                    # Artifact storage bucket
│   ├── lambda.tf                # Serverless function + IAM
│   ├── dynamodb.tf              # Metadata table + GSI
│   ├── ec2.tf                   # Web server instances
│   ├── security_groups.tf       # Network rules
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Resource outputs
│   ├── terraform.tfvars         # LocalStack values
│   └── backend.tf               # State configuration
│
├── lambda/                      # Serverless functions
│   ├── handler.py               # Python Lambda function
│   └── handler.zip              # Deployment package (generated)
│
├── docker/                      # LocalStack setup
│   ├── docker-compose.yml       # Container orchestration
│   └── .env                     # Auth token (not in git)
│
├── ansible/                     # Configuration management
│   ├── ansible.cfg              # Ansible settings
│   ├── inventory/hosts.ini      # Target hosts
│   └── playbooks/
│       └── configure_webserver.yml
│
├── scripts/                     # Automation helpers
│   ├── init.sh                  # Terraform init
│   ├── apply.sh                 # Terraform apply
│   └── destroy.sh               # Cleanup resources
│
└── Jenkinsfile                  # CI/CD pipeline definition
```

---

## Technologies Used

| Component | Technology | Purpose |
|-----------|------------|---------|
| **IaC** | Terraform 1.5+ | Declarative infrastructure provisioning |
| **Cloud Sim** | LocalStack  | AWS service simulation (EC2, S3, Lambda, DynamoDB) |
| **Compute** | AWS Lambda | Serverless artifact processing |
| **Storage** | AWS S3 | Versioned, encrypted artifact repository |
| **Database** | AWS DynamoDB | NoSQL metadata store with GSI |
| **Network** | AWS VPC | Custom networking with public subnets |
| **CI/CD** | Jenkins | Automated pipeline with security scanning |
| **Security** | tfsec + Checkov | Infrastructure security validation |
| **Config Mgmt** | Ansible | Automated server configuration |
| **Containers** | Docker Compose | LocalStack orchestration |

---

## Quick Start

### Prerequisites

- **Docker Desktop** (for LocalStack)
- **Terraform** ≥ 1.5.0
- **AWS CLI** v2
- **Python** 3.11+
- **PowerShell** 7+ (Windows) or Bash (Linux/Mac)
- **LocalStack Pro** auth token (GitHub Student Developer Pack)

### 1️⃣ Setup LocalStack

```powershell
cd D:\devops-project\DevOps-Project

echo "LOCALSTACK_AUTH_TOKEN=your-token-here" > docker\.env

cd docker
docker-compose up -d

docker ps
```

### 2️⃣ Deploy Infrastructure

```powershell
cd ..\terraform

terraform init

terraform plan

terraform apply -auto-approve
```

### 3️⃣ Test Lambda Function

```powershell
cd ..

# Invoke Lambda manually
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name devops-lab-artifacts-processor \
  --cli-binary-format raw-in-base64-out \
  --payload file://payload.json \
  response.json

# Check response
Get-Content response.json
```

### 4️⃣ Verify DynamoDB Records

```powershell
# View stored metadata
aws --endpoint-url=http://localhost:4566 dynamodb scan \
  --table-name devops-lab-artifacts-metadata
``