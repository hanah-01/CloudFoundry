# DevOps Project

**Infrastructure as Code (IaC) + LocalStack + Jenkins CI/CD**

## Project Overview

This project demonstrates modern DevOps practices by provisioning AWS infrastructure with Terraform, testing locally using LocalStack, and automating the workflow with Jenkins. The design supports a **local validation path** and a **real AWS path** using environment folders.

## Key Features

- **Infrastructure as Code**: Terraform module for VPC, S3, Lambda, DynamoDB, API Gateway, EC2, and monitoring
- **Cloud Simulation**: LocalStack for AWS service emulation
- **Serverless Pipeline**: S3 -> Lambda -> DynamoDB
- **Monitoring & Logging**: CloudWatch log groups and alarms
- **CI/CD Automation**: Jenkins pipeline with local + prod stages
- **Resource Friendly**: Production defaults minimize cost (single instance, no ALB/ASG)

---

## Architecture (High Level)

```
LocalStack (dev) / AWS (prod)

S3 Bucket -> Lambda (processor) -> DynamoDB (metadata)
                      |
                      +-> API Gateway (HTTP /process)
```

---

## Project Structure

```
DevOps-Project/
├── Jenkinsfile
├── Dockerfile
├── docker/
│   ├── docker-compose.yml
│   └── init-scripts/
│       ├── init-s3.sh
│       └── test.txt
├── lambda/
│   ├── handler.py
│   └── notifier.py
├── scripts/
│   ├── init.sh
│   ├── apply.sh
│   └── destroy.sh
├── terraform/
│   ├── environments/
│   │   ├── local/
│   │   └── prod/
│   └── modules/
│       └── web_stack/
└── ansible/
```

---

## LocalStack (Local Validation)

### Start LocalStack

```powershell
cd D:\devops-project\DevOps-Project
docker compose -f docker\docker-compose.yml up -d
```

### Terraform Init (Local)

```powershell
terraform -chdir=terraform/environments/local init
```

### Terraform Plan / Apply (Local)

```powershell
terraform -chdir=terraform/environments/local plan -out=tfplan
terraform -chdir=terraform/environments/local apply -auto-approve tfplan
```

### Verify

```powershell
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

> If you want to use the bash scripts, install Git Bash or WSL. The error
> `execvpe(/bin/bash) failed` means Bash is not installed on Windows.

---

## AWS 

### Step 1: Create AWS Backend (S3 + DynamoDB)

1. S3 bucket for state: `your-terraform-state-bucket`
2. DynamoDB table for lock: `terraform-state-lock` (partition key: `LockID`)

### Step 2: Configure backend.hcl

Copy and edit:

```
terraform/environments/prod/backend.hcl.example
```

Create:

```
terraform/environments/prod/backend.hcl
```

### Step 3: Minimal Cost Defaults

By default, prod runs with:
- `enable_load_balancer = false`
- `enable_self_healing = false`
- `desired_capacity = 1`

You can override in `terraform/environments/prod/terraform.tfvars`.

### Step 4: Apply

```powershell
terraform -chdir=terraform/environments/prod init -backend-config=backend.hcl
terraform -chdir=terraform/environments/prod plan -out=tfplan
terraform -chdir=terraform/environments/prod apply -auto-approve tfplan
```

---

## Jenkins CI/CD

Pipeline stages:

- **LocalStack Validation** 
  - Terraform init/plan/apply on LocalStack
  - Always destroyed after build for zero cost

- **AWS Deploy (Prod)** 
  - Runs only if `RUN_PROD=true` and branch is `main/master/temp-f`
  - Uses `backend.hcl` if present
  - Student-tier friendly settings (single instance, no ALB/ASG)

---

## Notes on Cost Safety

- Use LocalStack for most testing
- Only enable prod stage for demos
- Keep ALB and ASG disabled unless required
- Use t3.micro or t2.micro for EC2

---

## IAM Policy (Minimal)

See [docs/terraform-minimal-iam-policy.json](docs/terraform-minimal-iam-policy.json) for a minimal policy template.
