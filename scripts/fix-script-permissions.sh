#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="${1:-}"

if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

success() { echo -e "${GREEN}[scripts]${NC} $1"; }
warn() { echo -e "${YELLOW}[scripts]${NC} $1"; }
should_quit() { [[ "${1:-}" =~ ^[qQ]$ ]]; }

scripts=()
scripts_needing_update=()

while IFS= read -r -d '' script; do
    scripts+=("$script")
done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

echo
echo -e "${BLUE}==> Checking MD4N script permissions...${NC}"

if (( ${#scripts[@]} == 0 )); then
    warn "No action needed."
    echo
    exit 0
fi

for script in "${scripts[@]}"; do
    perms=$(stat -c '%a' "$script")
    name=$(basename "$script")

    if [[ "$perms" != "755" ]]; then
        scripts_needing_update+=("$script")
    fi

done

if (( ${#scripts_needing_update[@]} == 0 )); then
    success "No action needed."
    echo
    exit 0
fi

warn "Found scripts that need permission fixes."
for script in "${scripts[@]}"; do
    perms=$(stat -c '%a' "$script")
    name=$(basename "$script")

    if [[ ! -x "$script" ]]; then
        printf '  [%b%s%b] %b%s%b\n' "${RED}${BOLD}" "$perms" "${NC}" "${RED}${BOLD}" "${name} (not executable)" "${NC}"
    elif [[ "$perms" != "755" ]]; then
        printf '  [%b%s%b] %b%s%b\n' "${RED}${BOLD}" "$perms" "${NC}" "${RED}${BOLD}" "${name} (should be 755)" "${NC}"
    fi
done

prompt="$(printf '%b' "${BLUE}[?]${NC} Update MD4N script permissions now? [y/N] ")"
read -r -p "$prompt" confirm
if should_quit "$confirm"; then
    echo
    exit 0
fi

if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    warn "Skipped."
    echo
    exit 0
fi

chmod 755 "${scripts_needing_update[@]}"
success "Updated successfully."
echo
