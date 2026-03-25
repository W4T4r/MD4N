#!/usr/bin/env bash

# MD4N bootstrap script
# Prepares Nix flakes support, then hands off to scripts/setup.sh.

set -euo pipefail

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
step() { echo -e "\n${CYAN}==>${NC} ${BOLD}$1${NC}"; }

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

usage() {
    cat <<'EOF'
Usage: bash scripts/bootstrap.sh [options]

Options:
  --help    Show this help

bootstrap.sh checks Nix prerequisites, enables flakes if needed,
temporarily enables fzf via nix if needed, and then launches
scripts/setup.sh for the interactive setup.
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

is_feature_enabled() {
    local config_output=$1
    local feature=$2

    grep -Eq "(^|[[:space:]])${feature}([[:space:]]|$)" <<< "$config_output"
}

ensure_flakes_enabled() {
    local nix_config=""
    local nix_conf="/etc/nix/nix.conf"

    nix_config=$(nix config show 2>/dev/null || true)
    if is_feature_enabled "$nix_config" "flakes" && is_feature_enabled "$nix_config" "nix-command"; then
        success "No action needed."
        return 0
    fi

    warn "Found items that need attention."
    sudo mkdir -p /etc/nix

    if sudo test -f "$nix_conf" && sudo grep -Eq '^[[:space:]]*extra-experimental-features[[:space:]]*=.*\bnix-command\b.*\bflakes\b' "$nix_conf"; then
        success "No action needed."
        return 0
    fi

    echo "extra-experimental-features = nix-command flakes" | sudo tee -a "$nix_conf" >/dev/null
    success "Updated successfully."
}

detail() {
    echo -e "  ${GRAY}$1${NC}"
}

launch_setup() {
    if command -v fzf >/dev/null 2>&1; then
        info "fzf is already available in PATH."
        info "Running: bash ${SETUP_SCRIPT}"
        MD4N_CHAINED=1 bash "$SETUP_SCRIPT"
        return 0
    fi

    info "fzf is not installed in PATH. Starting setup inside a temporary nix shell."
    detail "Command: nix shell nixpkgs#fzf --command bash ${SETUP_SCRIPT}"
    MD4N_CHAINED=1 nix shell nixpkgs#fzf --command bash "$SETUP_SCRIPT"
}

print_banner() {
    echo
    if [[ "${MD4N_CHAINED:-0}" != "1" ]]; then
        print_logo
    fi
    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                 BOOTSTRAP CONSOLE                 " "${NC}"
    rule
    summary_row "Repository" "${ROOT_DIR}"
    summary_row "Previous" "install.sh"
    summary_row "Current" "bootstrap.sh"
    summary_row "Next" "setup.sh"
    summary_row "Flow" "install.sh -> bootstrap.sh -> setup.sh"
    summary_row "Purpose" "prepare Nix and launch interactive setup"
    rule
    echo "This stage verifies Nix prerequisites, enables flakes if needed, then hands off to setup."
    echo
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP_SCRIPT="${ROOT_DIR}/scripts/setup.sh"

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
esac

print_banner

require_command bash
require_command sudo
require_command nix

[[ -f "${ROOT_DIR}/flake.nix" ]] || error "Could not find flake.nix in ${ROOT_DIR}"
[[ -f "$SETUP_SCRIPT" ]] || error "Could not find the setup script at ${SETUP_SCRIPT}"

step "[1/3] Checking Nix prerequisites"
info "Required commands: bash, sudo, nix"
info "flake.nix location: ${ROOT_DIR}/flake.nix"

step "[2/3] Enabling MD4N Nix support"
ensure_flakes_enabled

step "[3/3] Launching MD4N setup"
info "Flow: install.sh -> bootstrap.sh -> setup.sh"
launch_setup

echo ""
success "Completed successfully."
