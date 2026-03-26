#!/usr/bin/env bash

# MD4N forge console
# Applies NixOS and/or Home Manager configuration from this repository.

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'
FZF_BLOCK_UNUSED_KEYS='a:ignore,b:ignore,c:ignore,d:ignore,e:ignore,f:ignore,g:ignore,h:ignore,i:ignore,l:ignore,m:ignore,n:ignore,o:ignore,p:ignore,r:ignore,s:ignore,t:ignore,u:ignore,v:ignore,w:ignore,x:ignore,y:ignore,z:ignore,A:ignore,B:ignore,C:ignore,D:ignore,E:ignore,F:ignore,G:ignore,H:ignore,I:ignore,J:ignore,K:ignore,L:ignore,M:ignore,N:ignore,O:ignore,P:ignore,R:ignore,S:ignore,T:ignore,U:ignore,V:ignore,W:ignore,X:ignore,Y:ignore,Z:ignore,0:ignore,1:ignore,2:ignore,3:ignore,4:ignore,5:ignore,6:ignore,7:ignore,8:ignore,9:ignore,space:ignore,bspace:ignore,del:ignore,ctrl-h:ignore,ctrl-u:ignore,ctrl-w:ignore,ctrl-a:ignore,ctrl-e:ignore,ctrl-f:ignore,ctrl-b:ignore,pgup:ignore,pgdn:ignore,home:ignore,end:ignore,left:ignore,right:ignore,tab:ignore,btab:ignore,esc:ignore,/:ignore,?:ignore,-:ignore,_:ignore,=:ignore,+:ignore,,:ignore,.:ignore'
MENU_SELECTION=""

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
detail() { echo -e "  ${DIM}$1${NC}"; }
should_quit() { [[ "${1:-}" =~ ^[qQ]$ ]]; }
exit_if_requested() {
    if should_quit "${1:-}"; then
        echo
        info "Exited."
        exit 0
    fi
}

rule() {
    printf '%b\n' "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

section() {
    echo
    printf '%b\n' "${CYAN}==>${NC} ${BOLD}$1${NC}"
}

summary_row() {
    printf '%b %-11s%b %s\n' "${GRAY}" "$1" "${NC}" "$2"
}

pad_dashboard_rows() {
    local current_rows=$1
    local target_rows=${2:-4}
    local i

    for ((i = current_rows; i < target_rows; i++)); do
        summary_row "" ""
    done
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

print_dashboard_body() {
    local root_dir=$1
    local username=$2
    local hostname=$3
    local target_mode=$4
    local flake_dir=$5

    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                  FORGE CONSOLE                  " "${NC}"
    rule
    summary_row "Repository" "${root_dir}"
    summary_row "Profile" "${username}@${hostname}"
    summary_row "Flake" "${flake_dir}"
    summary_row "Target" "${target_mode}"
    pad_dashboard_rows 4
    rule
}

print_dashboard() {
    local root_dir=$1
    local username=$2
    local hostname=$3
    local target_mode=$4
    local flake_dir=$5
    local apply_system_flag=$6
    local apply_home_flag=$7
    local apply_update_flag=$8
    printf '\033[H\033[2J'
    echo
    print_logo
    print_dashboard_body "$root_dir" "$username" "$hostname" "$target_mode" "$flake_dir" "$apply_system_flag" "$apply_home_flag" "$apply_update_flag"
}

select_menu() {
    local prompt=$1
    local height=${2:-40%}
    shift 2
    local options=("$@")
    local choice
    choice=$(printf '%s\n' "${options[@]}" | \
        env \
            -u FZF_DEFAULT_OPTS \
            -u FZF_DEFAULT_OPTS_FILE \
            -u FZF_TMUX \
            -u FZF_TMUX_OPTS \
            -u FZF_CTRL_T_OPTS \
            -u FZF_ALT_C_OPTS \
            FZF_DEFAULT_OPTS= \
        fzf \
            --layout=reverse \
            --border \
            --height="$height" \
            --no-input \
            --disabled \
            --header "${prompt}: j/k navigate, Enter select, q back" \
            --cycle \
            --bind "j:down,k:up,up:up,down:down,q:abort,${FZF_BLOCK_UNUSED_KEYS}") || return 1

    MENU_SELECTION="${choice%% *}"
    return 0
}

usage() {
    cat <<'EOF'
Usage: bash forge.sh [options]

Options:
  --os            Apply only the NixOS configuration
  --home          Apply only the Home Manager configuration
  --all           Apply both NixOS and Home Manager configurations
  --update        Update the flake.lock before applying
  --no-backup     Disable the md4nbak backup for Home Manager
  --help          Show this help

If no target option is provided, the script will show a menu for os, home, or all.
Press `q` in the menu to exit.
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

detect_user_field() {
    local user_nix=$1
    local field=$2
    awk -F'"' -v field="$field" '$0 ~ "^[[:space:]]*" field "[[:space:]]*=" {print $2; exit}' "$user_nix"
}

choose_target() {
    print_dashboard "$ROOT_DIR" "$USERNAME" "$HOSTNAME" "select target" "$ACTIVE_FLAKE_DIR" "true" "true" "true"
    echo -e "  Menu       : ${DIM}choose configuration target${NC}\n"
    if ! select_menu "Forge" "40%" \
        "os      apply only the NixOS configuration" \
        "home    apply only the Home Manager configuration" \
        "all     apply both" \
        "update  update flake.lock"; then
        echo "Returning to Top..."
        exit 0
    fi
    target_mode="$MENU_SELECTION"
}

apply_update() {
    local root_dir=$1

    require_command nix
    require_command sudo

    section "Flake Update"
    info "Updating flake.lock..."
    detail "Command: sudo nix flake update --flake ${root_dir}"
    sudo -v
    sudo nix flake update --flake "${root_dir}"
    success "Flake updated successfully."
}

apply_system() {
    local root_dir=$1
    local hostname=$2
    local flake_ref="path:${root_dir}#${hostname}"

    require_command sudo
    require_command nixos-rebuild

    section "NixOS Apply"
    info "Applying MD4N configuration..."
    detail "Command: sudo nixos-rebuild switch --flake ${flake_ref}"
    sudo -v
    sudo nixos-rebuild switch --flake "${flake_ref}"
    success "Completed successfully."
}

apply_home() {
    local flake_dir=$1
    local username=$2
    local backup_flag=$3
    local flake_ref="path:${flake_dir}#${username}"

    require_command home-manager

    section "Home Manager Apply"
    info "Applying MD4N configuration..."
    if [[ "$backup_flag" == "true" ]]; then
        detail "Command: home-manager switch -b md4nbak --flake ${flake_ref}"
        home-manager switch -b md4nbak --flake "${flake_ref}"
    else
        detail "Command: home-manager switch --flake ${flake_ref}"
        home-manager switch --flake "${flake_ref}"
    fi
    success "Completed successfully."
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCAL_DIR="${ROOT_DIR}/local"
LOCAL_GENERATED_DIR="${LOCAL_DIR}/generated"
LOCAL_FLAKE_FILE="${LOCAL_DIR}/flake.nix"
USER_NIX="${ROOT_DIR}/user.nix"
USER_LOCAL_NIX="${LOCAL_GENERATED_DIR}/user.nix"
LEGACY_USER_LOCAL_NIX="${ROOT_DIR}/user.local.nix"
ACTIVE_USER_NIX="$USER_NIX"
ACTIVE_FLAKE_DIR="$ROOT_DIR"

if [[ -f "$USER_LOCAL_NIX" ]]; then
    ACTIVE_USER_NIX="$USER_LOCAL_NIX"
elif [[ -f "$LEGACY_USER_LOCAL_NIX" ]]; then
    ACTIVE_USER_NIX="$LEGACY_USER_LOCAL_NIX"
fi

if [[ -f "$LOCAL_FLAKE_FILE" ]]; then
    ACTIVE_FLAKE_DIR="$LOCAL_DIR"
fi

apply_system_flag=true
apply_home_flag=true
apply_update_flag=false
home_backup=true
target_mode=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --os)
            apply_system_flag=true
            apply_home_flag=false
            target_mode="os"
            ;;
        --home)
            apply_system_flag=false
            apply_home_flag=true
            target_mode="home"
            ;;
        --all)
            apply_system_flag=true
            apply_home_flag=true
            target_mode="all"
            ;;
        --update)
            apply_update_flag=true
            ;;
        --no-backup)
            home_backup=false
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
    shift
done

[[ -f "${ROOT_DIR}/flake.nix" ]] || error "Could not find flake.nix in ${ROOT_DIR}"
[[ -f "$ACTIVE_USER_NIX" ]] || error "Could not find user.nix or local/generated/user.nix in ${ROOT_DIR}. Run setup first."
require_command fzf

USERNAME=$(detect_user_field "$ACTIVE_USER_NIX" "name")
HOSTNAME=$(detect_user_field "$ACTIVE_USER_NIX" "hostname")
[[ -n "$USERNAME" ]] || error "Could not determine username from ${ACTIVE_USER_NIX}"
[[ -n "$HOSTNAME" ]] || error "Could not determine hostname from ${ACTIVE_USER_NIX}"

if [[ -z "$target_mode" ]]; then
    choose_target
    target_mode="$MENU_SELECTION"
    case "$target_mode" in
        os)
            apply_system_flag=true
            apply_home_flag=false
            ;;
        home)
            apply_system_flag=false
            apply_home_flag=true
            ;;
        all)
            apply_system_flag=true
            apply_home_flag=true
            ;;
        update)
            apply_update_flag=true
            apply_system_flag=false
            apply_home_flag=false
            ;;
    esac
fi

print_dashboard "$ROOT_DIR" "$USERNAME" "$HOSTNAME" "$target_mode" "$ACTIVE_FLAKE_DIR" "$apply_system_flag" "$apply_home_flag" "$apply_update_flag"

if [[ "$apply_update_flag" == "true" ]]; then
    apply_update "$ACTIVE_FLAKE_DIR"
fi

if [[ "$apply_system_flag" == "true" ]]; then
    apply_system "$ACTIVE_FLAKE_DIR" "$HOSTNAME"
fi

if [[ "$apply_home_flag" == "true" ]]; then
    apply_home "$ACTIVE_FLAKE_DIR" "$USERNAME" "$home_backup"
fi

echo ""
success "Completed successfully."
