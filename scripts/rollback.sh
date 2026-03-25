#!/usr/bin/env bash

# rollback.sh - MD4N specific generation rollback tool
# Strictly controlled UI for switching generations.

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

# --- FZF Settings (Strictly blocked) ---
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
    local gen=$1
    local usage=$2

    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                  ROLLBACK CONSOLE               " "${NC}"
    rule
    summary_row "System Gen" "#${gen}"
    summary_row "Nix Usage"  "${usage}"
    pad_dashboard_rows 2
    rule
}

print_dashboard() {
    local gen
    local usage

    gen=$(current_system_generation || echo "?")
    usage=$(store_usage_human || echo "unknown")

    printf '\033[H\033[2J'
    echo
    print_logo
    print_dashboard_body "$gen" "$usage"
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

current_system_generation() {
    local target
    target=$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)
    [[ -n "$target" ]] || return 1
    basename "$target" | sed -E 's/.*-([0-9]+)-link/\1/'
}

store_usage_human() {
    local used size percent
    read -r used size percent _ < <(df -B1 --output=used,size,pcent,fstype /nix/store 2>/dev/null | tail -n 1) || return 1
    [[ -n "${used:-}" && -n "${size:-}" ]] || return 1
    printf '%s / %s (%s)' \
        "$(numfmt --to=iec-i --suffix=B --format='%.2f' "$used")" \
        "$(numfmt --to=iec-i --suffix=B --format='%.2f' "$size")" \
        "$percent"
}

get_home_manager_profile() {
    local candidates=(
        "$HOME/.local/state/nix/profiles/home-manager"
        "/nix/var/nix/profiles/per-user/$USER/home-manager"
    )
    for c in "${candidates[@]}"; do
        if [[ -e "$c" ]]; then echo "$c"; return 0; fi
    done
    return 1
}

perform_rollback() {
    local profile=$1
    local target_name=$2
    local use_sudo=${3:-false}

    local gens_raw
    if [[ "$use_sudo" == "true" ]]; then
        gens_raw=$(sudo nix-env --profile "$profile" --list-generations 2>/dev/null)
    else
        gens_raw=$(nix-env --profile "$profile" --list-generations 2>/dev/null)
    fi

    [[ -n "$gens_raw" ]] || { warn "No generations found."; return 1; }

    # Format for FZF selection
    local formatted_gens
    formatted_gens=$(echo "$gens_raw" | awk '{$1=$1; print $0}')

    print_dashboard
    echo -e "  Action     : ${CYAN}select generation to switch to (${target_name})${NC}\n"
    
    local options=()
    while IFS= read -r line; do
        options+=("$line")
    done <<< "$formatted_gens"

    select_menu "Select Generation" "50%" "${options[@]}"
    local choice="$MENU_SELECTION"
    [[ -n "$choice" ]] || return 0

    echo -e "\n${YELLOW}${BOLD}! Switching ${target_name} to generation ${choice}...${NC}"
    
    if [[ "$use_sudo" == "true" ]]; then
        sudo nix-env --profile "$profile" --switch-generation "$choice"
        info "Activating system configuration..."
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    else
        nix-env --profile "$profile" --switch-generation "$choice"
        info "Activating user configuration..."
        "${profile}/activate"
    fi
    
    success "Switched to #${choice}."
    sleep 2
}

# --- Main Loop ---
command -v fzf >/dev/null 2>&1 || error "Missing fzf"

while true; do
    print_dashboard
    echo -e "  Menu       : ${DIM}choose rollback target${NC}\n"
    
    options=(
        "os      select and rollback NixOS"
        "home    select and rollback Home Manager"
    )

    if ! select_menu "Rollback" "40%" "${options[@]}"; then
        exit 0
    fi

    case "$MENU_SELECTION" in
        os)   perform_rollback "/nix/var/nix/profiles/system" "NixOS" true ;;
        home) 
            hm_profile=$(get_home_manager_profile) || { warn "HM profile not found."; sleep 1; continue; }
            perform_rollback "$hm_profile" "Home Manager" false ;;
    esac
done
