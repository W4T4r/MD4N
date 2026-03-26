#!/usr/bin/env bash

# MD4N bootstrap script
# Prepares Nix flakes support, then hands off to scripts/configure-local.sh.

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
detail() { echo -e "  ${GRAY}$1${NC}"; }

is_interactive() {
    [[ -t 0 ]]
}

prompt_yes_no() {
    local prompt=$1
    local default_value=${2:-true}
    local answer=""

    if ! is_interactive; then
        [[ "$default_value" == "true" ]]
        return
    fi

    if [[ "$default_value" == "true" ]]; then
        read -r -p "${prompt} [Y/n] " answer
        [[ ! "$answer" =~ ^[nN]$ ]]
        return
    fi

    read -r -p "${prompt} [y/N] " answer
    [[ "$answer" =~ ^[yY]$ ]]
}

path_state_label() {
    if [[ -e "$1" ]]; then
        printf 'existing'
    else
        printf 'pending'
    fi
}

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
scripts/configure-local.sh for the interactive local configuration.
The setup flow is centered on local/flake.nix, local/generated/user.nix,
and the local override trees under local/nixos/ and local/home-manager/.
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
    detail "Target file: ${nix_conf}"

    if ! prompt_yes_no "Enable nix-command and flakes for this machine now?" "true"; then
        error "Flakes support is required to continue the local setup flow."
    fi

    sudo mkdir -p /etc/nix

    if sudo test -f "$nix_conf" && sudo grep -Eq '^[[:space:]]*extra-experimental-features[[:space:]]*=.*\bnix-command\b.*\bflakes\b' "$nix_conf"; then
        success "No action needed."
        return 0
    fi

    echo "extra-experimental-features = nix-command flakes" | sudo tee -a "$nix_conf" >/dev/null
    success "Updated successfully."
}
launch_setup() {
    if ! prompt_yes_no "Launch the interactive local setup now?" "true"; then
        info "Bootstrap finished without starting local configuration."
        return 0
    fi

    if command -v fzf >/dev/null 2>&1; then
        info "fzf is already available in PATH."
        info "Running: bash ${CONFIGURE_LOCAL_SCRIPT}"
        MD4N_CHAINED=1 bash "$CONFIGURE_LOCAL_SCRIPT"
        return 0
    fi

    info "fzf is not installed in PATH. Starting local configuration inside a temporary nix shell."
    detail "Command: nix shell nixpkgs#fzf --command bash ${CONFIGURE_LOCAL_SCRIPT}"

    if ! prompt_yes_no "Use a temporary nix shell to provide fzf for the local setup?" "true"; then
        error "fzf is required for the interactive consoles."
    fi

    MD4N_CHAINED=1 nix shell nixpkgs#fzf --command bash "$CONFIGURE_LOCAL_SCRIPT"
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
    summary_row "Next" "configure-local.sh"
    summary_row "Flow" "install.sh -> bootstrap.sh -> configure-local.sh"
    summary_row "Local flake" "$(path_state_label "$LOCAL_FLAKE_FILE")"
    summary_row "Local user" "$(path_state_label "$LOCAL_GENERATED_USER_NIX")"
    summary_row "Purpose" "prepare Nix and launch local setup"
    rule
    echo "This stage verifies Nix prerequisites, reviews the local targets, enables flakes if needed, and then hands off to local configuration."
    echo
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIGURE_LOCAL_SCRIPT="${ROOT_DIR}/scripts/configure-local.sh"
LOCAL_DIR="${ROOT_DIR}/local"
LOCAL_FLAKE_FILE="${LOCAL_DIR}/flake.nix"
LOCAL_GENERATED_USER_NIX="${LOCAL_DIR}/generated/user.nix"
LOCAL_NIXOS_DIR="${LOCAL_DIR}/nixos"
LOCAL_HOME_MANAGER_DIR="${LOCAL_DIR}/home-manager"

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
[[ -f "$CONFIGURE_LOCAL_SCRIPT" ]] || error "Could not find the local configuration script at ${CONFIGURE_LOCAL_SCRIPT}"

step "[1/4] Reviewing local setup targets"
info "This flow configures the ignored local tree for this machine."
detail "Shared base flake : ${ROOT_DIR}/flake.nix"
detail "Local flake       : ${LOCAL_FLAKE_FILE} ($(path_state_label "$LOCAL_FLAKE_FILE"))"
detail "Generated user    : ${LOCAL_GENERATED_USER_NIX} ($(path_state_label "$LOCAL_GENERATED_USER_NIX"))"
detail "Local NixOS tree  : ${LOCAL_NIXOS_DIR}"
detail "Local HM tree     : ${LOCAL_HOME_MANAGER_DIR}"
if [[ -e "$LOCAL_FLAKE_FILE" || -e "$LOCAL_GENERATED_USER_NIX" ]]; then
    warn "Existing local state detected. configure-local.sh can regenerate or update it."
fi

step "[2/4] Checking Nix prerequisites"
info "Required commands: bash, sudo, nix"
info "flake.nix location: ${ROOT_DIR}/flake.nix"

step "[3/4] Enabling MD4N Nix support"
ensure_flakes_enabled

step "[4/4] Launching MD4N local configuration"
info "Flow: install.sh -> bootstrap.sh -> configure-local.sh"
launch_setup

echo ""
success "Completed successfully."
