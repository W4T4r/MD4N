#!/usr/bin/env bash

# mn.sh - MD4N TOP HUB
# Top-level entry point for MD4N scripts and tools.

set -euo pipefail

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- FZF Settings ---
FZF_BLOCK_UNUSED_KEYS='a:ignore,b:ignore,c:ignore,d:ignore,e:ignore,f:ignore,g:ignore,h:ignore,i:ignore,l:ignore,m:ignore,n:ignore,o:ignore,p:ignore,r:ignore,s:ignore,t:ignore,u:ignore,v:ignore,w:ignore,x:ignore,y:ignore,z:ignore,A:ignore,B:ignore,C:ignore,D:ignore,E:ignore,F:ignore,G:ignore,H:ignore,I:ignore,J:ignore,K:ignore,L:ignore,M:ignore,N:ignore,O:ignore,P:ignore,R:ignore,S:ignore,T:ignore,U:ignore,V:ignore,W:ignore,X:ignore,Y:ignore,Z:ignore,0:ignore,1:ignore,2:ignore,3:ignore,4:ignore,5:ignore,6:ignore,7:ignore,8:ignore,9:ignore,space:ignore,bspace:ignore,del:ignore,ctrl-h:ignore,ctrl-u:ignore,ctrl-w:ignore,ctrl-a:ignore,ctrl-e:ignore,ctrl-f:ignore,ctrl-b:ignore,pgup:ignore,pgdn:ignore,home:ignore,end:ignore,left:ignore,right:ignore,tab:ignore,btab:ignore,esc:ignore,/:ignore,?:ignore,-:ignore,_:ignore,=:ignore,+:ignore,,:ignore,.:ignore'
MENU_SELECTION=""

# --- Helpers ---
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
detail() { echo -e "  ${DIM}$1${NC}"; }

rule() {
    printf '%b\n' "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    local flake_dir=$4

    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                  MD4N TOP                       " "${NC}"
    rule
    summary_row "Repository" "${root_dir}"
    summary_row "User"       "${username}"
    summary_row "Host"       "${hostname}"
    summary_row "Flake"      "${flake_dir}"
    pad_dashboard_rows 4
    rule
}

print_dashboard() {
    local root_dir=$1
    local username=$2
    local hostname=$3
    local flake_dir=$4

    printf '\033[H\033[2J'
    echo
    print_logo
    print_dashboard_body "$root_dir" "$username" "$hostname" "$flake_dir"
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
            --header "${prompt}: j/k navigate, Enter select, q exit" \
            --cycle \
            --bind "j:down,k:up,up:up,down:down,q:abort,${FZF_BLOCK_UNUSED_KEYS}") || return 1

    MENU_SELECTION="${choice%% *}"
    return 0
}

detect_user_field() {
    local user_nix=$1
    local field=$2
    if [[ -f "$user_nix" ]]; then
        awk -F'"' -v field="$field" '$0 ~ "^[[:space:]]*" field "[[:space:]]*=" {print $2; exit}' "$user_nix"
    fi
}

# --- Main Logic ---
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

USERNAME=$(detect_user_field "$ACTIVE_USER_NIX" "name")
HOSTNAME=$(detect_user_field "$ACTIVE_USER_NIX" "hostname")
USERNAME=${USERNAME:-$(whoami)}
HOSTNAME=${HOSTNAME:-$(hostname)}

command -v fzf >/dev/null 2>&1 || error "Missing required command: fzf"

while true; do
    print_dashboard "$ROOT_DIR" "$USERNAME" "$HOSTNAME" "$ACTIVE_FLAKE_DIR"
    echo -e "  Menu       : ${DIM}choose a tool to launch${NC}\n"

    options=(
        "local      regenerate machine-local configuration"
        "display    regenerate Niri display outputs"
        "forge      apply configuration"
        "rollback   revert to previous generation"
        "tune       maintenance console"
    )

    if ! select_menu "MD4N" "40%" "${options[@]}"; then
        echo -e "\n${BLUE}Bye!${NC}"
        exit 0
    fi

    main_choice="$MENU_SELECTION"

    case "$main_choice" in
        local)    bash "${SCRIPT_DIR}/configure-local.sh" ;;
        display)  bash "${SCRIPT_DIR}/configure-niri-outputs.sh" ;;
        forge)    bash "${SCRIPT_DIR}/forge.sh" ;;
        rollback) bash "${SCRIPT_DIR}/rollback.sh" ;;
        tune)     bash "${SCRIPT_DIR}/tune.sh" ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done
