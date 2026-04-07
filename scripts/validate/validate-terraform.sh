#!/usr/bin/env bash
#
# validate-terraform.sh — Validate Terraform formatting and configuration
#
# Checks:
#   1. terraform fmt -check -recursive on terraform/
#   2. terraform validate on terraform/dev/
#
# Exit code: non-zero if any check fails.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TERRAFORM_DIR="${REPO_ROOT}/terraform"
TERRAFORM_DEV_DIR="${TERRAFORM_DIR}/dev"
EXIT_CODE=0

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[PASS]\033[0m  $*"; }
fail()  { echo -e "\033[1;31m[FAIL]\033[0m  $*"; }

# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------
if ! command -v terraform &>/dev/null; then
  fail "terraform CLI not found. Please install Terraform."
  exit 1
fi

echo ""
info "============================================="
info "  Terraform Validation"
info "============================================="
echo ""

# ---------------------------------------------------------------------------
# Step 1 — Format check
# ---------------------------------------------------------------------------
info "Running 'terraform fmt -check -recursive' on ${TERRAFORM_DIR}..."

if terraform fmt -check -recursive "${TERRAFORM_DIR}"; then
  ok "Terraform formatting is correct"
else
  fail "Terraform formatting errors detected. Run 'terraform fmt -recursive terraform/' to fix."
  EXIT_CODE=1
fi

echo ""

# ---------------------------------------------------------------------------
# Step 2 — Validate configuration
# ---------------------------------------------------------------------------
if [[ -d "${TERRAFORM_DEV_DIR}" ]]; then
  info "Running 'terraform validate' on ${TERRAFORM_DEV_DIR}..."

  # Initialize without backend so we can validate locally
  terraform -chdir="${TERRAFORM_DEV_DIR}" init -backend=false -input=false -no-color 2>&1 | \
    while IFS= read -r line; do echo "  ${line}"; done

  if terraform -chdir="${TERRAFORM_DEV_DIR}" validate -no-color; then
    ok "Terraform configuration is valid"
  else
    fail "Terraform validation failed for terraform/dev/"
    EXIT_CODE=1
  fi
else
  info "Directory terraform/dev/ not found — skipping terraform validate"
fi

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [[ "${EXIT_CODE}" -eq 0 ]]; then
  ok "All Terraform checks passed"
else
  fail "One or more Terraform checks failed"
fi

exit "${EXIT_CODE}"
