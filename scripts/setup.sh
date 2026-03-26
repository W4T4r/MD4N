#!/usr/bin/env bash

# setup.sh - Compatibility wrapper for configure-local.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/configure-local.sh"

if [[ -t 1 ]]; then
    printf "\033[1;33m[WARN]\033[0m scripts/setup.sh is kept as a compatibility alias. Prefer \`bash scripts/configure-local.sh\`.\n"
fi

exec bash "$TARGET_SCRIPT" "$@"
