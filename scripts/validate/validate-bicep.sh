#!/usr/bin/env bash
#
# validate-bicep.sh — Validate Bicep templates
#
# Checks:
#   1. az bicep build on every .bicep file under bicep/
#   2. az bicep lint on every .bicep file (if supported by installed version)
#
# Exit code: non-zero if any check fails.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BICEP_DIR="${REPO_ROOT}/bicep"
EXIT_CODE=0

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[PASS]\033[0m  $*"; }
fail()  { echo -e "\033[1;31m[FAIL]\033[0m  $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }

# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------
if ! command -v az &>/dev/null; then
  fail "Azure CLI (az) not found. Please install the Azure CLI."
  exit 1
fi

# Ensure the bicep extension is available
if ! az bicep version &>/dev/null; then
  info "Installing Bicep CLI via Azure CLI..."
  az bicep install
fi

echo ""
info "============================================="
info "  Bicep Validation"
info "============================================="
echo ""

# ---------------------------------------------------------------------------
# Discover all .bicep files
# ---------------------------------------------------------------------------
mapfile -t BICEP_FILES < <(find "${BICEP_DIR}" -type f -name '*.bicep' 2>/dev/null)

if [[ ${#BICEP_FILES[@]} -eq 0 ]]; then
  warn "No .bicep files found under ${BICEP_DIR}"
  exit 0
fi

info "Found ${#BICEP_FILES[@]} Bicep file(s) to validate"
echo ""

# ---------------------------------------------------------------------------
# Step 1 — Build all Bicep files
# ---------------------------------------------------------------------------
info "Running 'az bicep build' on all .bicep files..."

for file in "${BICEP_FILES[@]}"; do
  REL_PATH="${file#"${REPO_ROOT}/"}"
  if az bicep build --file "${file}" --stdout >/dev/null 2>&1; then
    ok "Build succeeded: ${REL_PATH}"
  else
    fail "Build failed:   ${REL_PATH}"
    # Show the actual error for debugging
    az bicep build --file "${file}" 2>&1 | sed 's/^/       /' || true
    EXIT_CODE=1
  fi
done

echo ""

# ---------------------------------------------------------------------------
# Step 2 — Lint all Bicep files (if supported)
# ---------------------------------------------------------------------------
info "Checking if 'az bicep lint' is available..."

if az bicep lint --help &>/dev/null; then
  info "Running 'az bicep lint' on all .bicep files..."

  for file in "${BICEP_FILES[@]}"; do
    REL_PATH="${file#"${REPO_ROOT}/"}"
    if az bicep lint --file "${file}" 2>&1; then
      ok "Lint passed: ${REL_PATH}"
    else
      fail "Lint failed: ${REL_PATH}"
      EXIT_CODE=1
    fi
  done
else
  warn "'az bicep lint' not available in this version — skipping lint step"
fi

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [[ "${EXIT_CODE}" -eq 0 ]]; then
  ok "All Bicep checks passed"
else
  fail "One or more Bicep checks failed"
fi

exit "${EXIT_CODE}"
