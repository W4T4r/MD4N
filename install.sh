#!/usr/bin/env bash

set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="${ROOT_DIR}/scripts/bootstrap.sh"
CONFIGURE_LOCAL_SCRIPT="${ROOT_DIR}/scripts/configure-local.sh"
USER_NIX_BAK="${ROOT_DIR}/user.nix.bak"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

rule() {
    printf '%b\n' "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

summary_row() {
    printf '%b %-11s%b %s\n' "${GRAY}" "$1" "${NC}" "$2"
}

print_logo() {
    printf '%b\n' \
        "${BLUE}${BOLD}███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗${NC}" \
        "${BLUE}${BOLD}████╗ ████║██╔══██╗██║  ██║████╗  ██║${NC}" \
        "${BLUE}${BOLD}██╔████╔██║██║  ██║███████║██╔██╗ ██║${NC}" \
        "${BLUE}${BOLD}██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║${NC}" \
        "${BLUE}${BOLD}██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║${NC}" \
        "${BLUE}${BOLD}╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝${NC}"
}

print_banner() {
    echo
    print_logo
    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                 INSTALL ENTRYPOINT                 " "${NC}"
    rule
    summary_row "Repository" "${ROOT_DIR}"
    summary_row "Current" "install.sh"
    summary_row "Flow" "install.sh -> bootstrap.sh -> configure-local.sh"
    summary_row "Next" "${BOOTSTRAP_SCRIPT}"
    rule
}

usage() {
    cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --help    Show this help

This is the repository entrypoint. It delegates to scripts/bootstrap.sh.
EOF
}

if [[ ! -f "$BOOTSTRAP_SCRIPT" ]]; then
    error "Could not find bootstrap script at ${BOOTSTRAP_SCRIPT}"
fi

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
esac

print_banner
info "This entrypoint cleans transient setup state and forwards into bootstrap."
info "Delegating to: ${BOOTSTRAP_SCRIPT}"
info "Bootstrap will then continue to: ${CONFIGURE_LOCAL_SCRIPT}"
if [[ -f "$USER_NIX_BAK" ]]; then
    warn "Removing stale backup: ${USER_NIX_BAK}"
    rm -f "$USER_NIX_BAK"
fi
echo ""

MD4N_CHAINED=1 bash "$BOOTSTRAP_SCRIPT" "$@"
