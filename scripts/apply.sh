#!/usr/bin/env bash
# ============================================================
# apply.sh  –  Plan, security-scan, and apply Terraform
#
# Usage:  bash scripts/apply.sh [environment]
#         environment defaults to "dev"
# ============================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

ENV="${1:-dev}"
TF_DIR="terraform"

info "===== Terraform Apply  (env=${ENV}) ====="

# ── Ensure LocalStack is running ──────────────────────────
if ! curl -sf http://localhost:4566/_localstack/health >/dev/null 2>&1; then
  warn "LocalStack doesn't appear to be running. Starting it..."
  docker compose -f docker/docker-compose.yml up -d
  sleep 10
fi

cd "$TF_DIR"

# ── Format check ─────────────────────────────────────────
info "Running terraform fmt check..."
terraform fmt -check -recursive || warn "Formatting issues found. Run: terraform fmt -recursive"

# ── Init ─────────────────────────────────────────────────
info "Running terraform init..."
terraform init -input=false

# ── Validate ─────────────────────────────────────────────
info "Running terraform validate..."
terraform validate

# ── Optional security scans ──────────────────────────────
if command -v tfsec >/dev/null 2>&1; then
  info "Running tfsec security scan..."
  tfsec . --no-colour || warn "tfsec found issues (non-blocking in local run)"
else
  warn "tfsec not installed – skipping. Install: https://github.com/aquasecurity/tfsec"
fi

if command -v checkov >/dev/null 2>&1; then
  info "Running checkov security scan..."
  checkov -d . --framework terraform --quiet || warn "Checkov found issues (non-blocking in local run)"
else
  warn "checkov not installed – skipping. Install: pip install checkov"
fi

# ── Plan ─────────────────────────────────────────────────
info "Running terraform plan..."
terraform plan \
  -input=false \
  -var="environment=${ENV}" \
  -out=tfplan

# ── Confirm before apply ─────────────────────────────────
echo ""
read -r -p "Apply the above plan? [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
  info "Apply cancelled."
  exit 0
fi

# ── Apply ─────────────────────────────────────────────────
info "Running terraform apply..."
terraform apply -input=false tfplan

# ── Show outputs ─────────────────────────────────────────
info "Terraform outputs:"
terraform output

cd ..
info "===== Apply complete! ====="
