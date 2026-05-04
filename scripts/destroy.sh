#!/usr/bin/env bash
# ============================================================
# destroy.sh  –  Tear down all Terraform-managed resources
#                and stop LocalStack
#
# Usage:  bash scripts/destroy.sh
# ============================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

ENV="${1:-local}"
TF_DIR="terraform/environments/${ENV}"

if [ ! -d "${TF_DIR}" ]; then
  error "Terraform environment folder not found: ${TF_DIR}"
fi

info "===== Terraform Destroy (env=${ENV}) ====="
warn "This will DESTROY all simulated infrastructure!"
echo ""
read -r -p "Type 'yes' to confirm: " confirm

if [[ "${confirm}" != "yes" ]]; then
  info "Destroy cancelled."
  exit 0
fi

cd "$TF_DIR"

# ── Destroy ───────────────────────────────────────────────
info "Running terraform destroy..."
terraform destroy -auto-approve

# ── Clean up plan file ────────────────────────────────────
[ -f tfplan ] && rm -f tfplan && info "Removed tfplan."

cd ..

# ── Stop LocalStack ───────────────────────────────────────
if [ "${ENV}" = "local" ]; then
  read -r -p "Stop LocalStack too? [y/N] " stop_ls
  if [[ "${stop_ls,,}" == "y" ]]; then
    info "Stopping LocalStack..."
    docker compose -f docker/docker-compose.yml down -v
    info "LocalStack stopped."
  fi
fi

info "===== Destroy complete ====="
