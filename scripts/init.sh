#!/usr/bin/env bash
# ============================================================
# init.sh  –  One-time setup script
# Run this once to bootstrap your local environment.
#
# Usage:  bash scripts/init.sh
# ============================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

info "===== DevOps-Lab Environment Initializer ====="

# ── 1. Check prerequisites ─────────────────────────────────
info "Checking prerequisites..."

command -v docker    >/dev/null 2>&1 || error "Docker is not installed. Install Docker Desktop first."
command -v terraform >/dev/null 2>&1 || error "Terraform is not installed. Download from https://developer.hashicorp.com/terraform/downloads"
command -v ansible   >/dev/null 2>&1 || warn  "Ansible not found. Install it to use configuration management features."

info "Prerequisites OK."

# ── 2. Start LocalStack ────────────────────────────────────
info "Starting LocalStack via Docker Compose..."
docker compose -f docker/docker-compose.yml up -d

info "Waiting for LocalStack to be healthy..."
attempt=0
max_attempts=60
until curl -sf http://localhost:4566/_localstack/health \
      | grep -q '"s3": "running"' 2>/dev/null; do
  attempt=$((attempt + 1))
  if [ $attempt -ge $max_attempts ]; then
    error "LocalStack did not become healthy after ${max_attempts} attempts."
  fi
  echo -n "."
  sleep 5
done
echo ""
info "LocalStack is ready!"

# ── 3. Terraform init ──────────────────────────────────────
info "Running terraform init..."
cd terraform
terraform init -input=false
cd ..
info "Terraform initialized."

# ── 4. Done ────────────────────────────────────────────────
info "===== Setup complete ====="
info "Next steps:"
echo "  1.  bash scripts/apply.sh     – Plan & apply infrastructure"
echo "  2.  bash scripts/destroy.sh   – Tear down everything"
