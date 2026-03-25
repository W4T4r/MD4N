#!/usr/bin/env bash

# tune.sh - MD4N maintenance console
# Handles generation cleanup, garbage collection, and store optimization.

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

# --- Globals ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NIX="${ROOT_DIR}/user.nix"
USER_LOCAL_NIX="${ROOT_DIR}/user.local.nix"
USERNAME="User"
CHOSEN_GENERATIONS=""
CHOSEN_PACKAGES=""
USER_PROFILE_SENTINEL="__MD4N_USER_PROFILE__"

# --- Initialization ---
if [[ -f "$USER_LOCAL_NIX" ]]; then
    USERNAME=$(awk -F'"' '/^[[:space:]]*name[[:space:]]*=/ {print $2; exit}' "$USER_LOCAL_NIX")
elif [[ -f "$USER_NIX" ]]; then
    USERNAME=$(awk -F'"' '/^[[:space:]]*name[[:space:]]*=/ {print $2; exit}' "$USER_NIX")
fi

# --- UI Helpers ---
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
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                   TUNE CONSOLE                   " "${NC}"
    rule
    summary_row "System Gen" "#${gen}"
    summary_row "Nix Usage"  "${usage}"
    pad_dashboard_rows 2
    rule
}

print_dashboard() {
    local gen=${1:-?}
    local usage=${2:-unknown}

    printf '\033[H\033[2J'
    echo
    print_logo
    print_dashboard_body "$gen" "$usage"
}

wait_key() {
    [[ -t 0 ]] || return 0
    echo ""
    read -n 1 -s -r -p "Press any key to continue... (q to exit) "
    if [[ "${REPLY:-}" =~ ^[qQ]$ ]]; then exit 0; fi
    echo ""
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

# --- System Helpers ---
current_system_generation() {
    local target
    target=$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)
    [[ -n "$target" ]] || return 1
    basename "$target" | sed -E 's/.*-([0-9]+)-link/\1/'
}

store_usage_human() {
    local used size percent fstype
    read -r used size percent fstype < <(df -B1 --output=used,size,pcent,fstype /nix/store 2>/dev/null | tail -n 1) || return 1
    [[ -n "${used:-}" && -n "${size:-}" ]] || return 1
    printf '%s / %s (%s)' \
        "$(numfmt --to=iec-i --suffix=B --format='%.2f' "$used")" \
        "$(numfmt --to=iec-i --suffix=B --format='%.2f' "$size")" \
        "$percent"
}

# --- Generation Management (Simplified for Dashboard consistency) ---
format_generation_listing() {
    awk -v green="${GREEN}${BOLD}" -v nc="${NC}" '
        /^[[:space:]]*[0-9]+[[:space:]]+/ {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            split(line, parts, /[[:space:]]+/)
            gen = parts[1]
            # Replace the duplicate ID with the date/time string
            sub(/^[0-9]+[[:space:]]+[0-9]+[[:space:]]+/, "[" gen "] ", line)
            if (line ~ /\(current\)/) printf "%s%s%s\n", green, line, nc
            else printf "%s\n", line
        }
    '
}

list_generations() {
    local profile=$1
    if [[ "$profile" == "/nix/var/nix/profiles/system" ]]; then
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations 2>/dev/null | format_generation_listing
    elif [[ "$profile" == "$USER_PROFILE_SENTINEL" ]]; then
        nix-env --list-generations 2>/dev/null | format_generation_listing
    else
        nix-env --profile "$profile" --list-generations 2>/dev/null | format_generation_listing
    fi
}

choose_generations() {
    local profile=$1
    local display_profile=$profile
    local all_gens ids
    
    if [[ "$profile" == "$USER_PROFILE_SENTINEL" ]]; then
        display_profile="${USERNAME} user profile"
    fi
    
    CHOSEN_GENERATIONS=""
    all_gens=$(list_generations "$profile")
    [[ -n "$all_gens" ]] || { warn "No generations found."; return 1; }
    
    print_dashboard "$(current_system_generation)" "$(store_usage_human)"
    echo -e "  Action     : ${CYAN}select generations to delete for ${display_profile}${NC}\n"
    
    echo "$all_gens"
    echo ""
    read -r -p "Enter IDs to delete (e.g. 10 12-16, blank to cancel): " ids
    [[ -n "${ids// }" ]] || return 0

    CHOSEN_GENERATIONS=$(printf '%s\n' "$all_gens" | awk -v ids="$ids" '
        BEGIN { split(ids, w, /[[:space:]]+/)
            for (i in w) {
                if (w[i] ~ /^[0-9]+-[0-9]+$/) {
                    split(w[i], b, "-"); for (n=(b[1]<b[2]?b[1]:b[2]); n<=(b[1]>b[2]?b[1]:b[2]); n++) s[n]=1
                } else if (w[i] ~ /^[0-9]+$/) s[w[i]]=1
            }
        }
        match($1, /^\[([0-9]+)\]$/, c) && s[c[1]] && $0 !~ /current/ { print }
    ')
}

delete_generations() {
    local profile=$1 selected=$2 use_sudo=${3:-false} ids
    ids=$(printf '%s\n' "$selected" | sed -E 's/^\[([0-9]+)\].*/\1/')
    while read -r id; do
        [[ -n "$id" ]] || continue
        detail "Deleting generation $id..."
        if [[ "$profile" == "$USER_PROFILE_SENTINEL" ]]; then nix-env --delete-generations "$id"
        elif [[ "$use_sudo" == "true" ]]; then sudo nix-env --profile "$profile" --delete-generations "$id"
        else nix-env --profile "$profile" --delete-generations "$id"
        fi
    done <<< "$ids"
}

manage_system_generations() {
    print_dashboard "$(current_system_generation)" "$(store_usage_human)"
    if choose_generations /nix/var/nix/profiles/system; then
        if [[ -n "$CHOSEN_GENERATIONS" ]]; then
            echo -e "\n${RED}${BOLD}Following system generations will be deleted:${NC}\n$CHOSEN_GENERATIONS\n"
            read -r -p "Are you sure? [y/N] " confirm
            if [[ "$confirm" =~ ^[yY]$ ]]; then
                delete_generations /nix/var/nix/profiles/system "$CHOSEN_GENERATIONS" true
                success "Deleted. Running GC..."
                sudo nix-collect-garbage
            fi
        fi
    fi
    wait_key
}

optimize_store() {
    print_dashboard "$(current_system_generation)" "$(store_usage_human)"
    echo -e "  Menu       : ${DIM}choose optimization task${NC}\n"
    if ! select_menu "Store" "40%" "1 GC" "2 Deduplicate" "3 Full"; then
        return 0
    fi
    case "$MENU_SELECTION" in
        1) sudo nix-collect-garbage -d ;;
        2) sudo nix-store --optimise ;;
        3) sudo nix-collect-garbage -d && sudo nix-store --optimise ;;
    esac
    wait_key
}

# --- Main Loop ---
command -v fzf >/dev/null 2>&1 || error "Missing required command: fzf"

while true; do
    print_dashboard "$(current_system_generation)" "$(store_usage_human)"
    echo -e "  Menu       : ${DIM}choose a maintenance task${NC}\n"
    
    options=(
        "system   manage system generations"
        "user     manage user profile generations"
        "home     manage home manager generations"
        "opt      optimize store"
        "clean    auto-clean everything"
    )

    if ! select_menu "Maintenance" "40%" "${options[@]}"; then
        exit 0
    fi

    case "$MENU_SELECTION" in
        system) manage_system_generations ;;
        user)   
            print_dashboard "$(current_system_generation)" "$(store_usage_human)"
            if choose_generations "$USER_PROFILE_SENTINEL"; then
                if [[ -n "$CHOSEN_GENERATIONS" ]]; then
                    echo -e "\n${RED}${BOLD}Following user generations will be deleted:${NC}\n$CHOSEN_GENERATIONS\n"
                    read -r -p "Are you sure? [y/N] " confirm
                    if [[ "$confirm" =~ ^[yY]$ ]]; then
                        delete_generations "$USER_PROFILE_SENTINEL" "$CHOSEN_GENERATIONS"
                        nix-collect-garbage
                    fi
                fi
            fi
            wait_key ;;
        home)
            print_dashboard "$(current_system_generation)" "$(store_usage_human)"
            profile="$HOME/.local/state/nix/profiles/home-manager"
            if [[ ! -e "$profile" ]]; then profile="/nix/var/nix/profiles/per-user/$USER/home-manager"; fi
            if choose_generations "$profile"; then
                if [[ -n "$CHOSEN_GENERATIONS" ]]; then
                    echo -e "\n${RED}${BOLD}Following home manager generations will be deleted:${NC}\n$CHOSEN_GENERATIONS\n"
                    read -r -p "Are you sure? [y/N] " confirm
                    if [[ "$confirm" =~ ^[yY]$ ]]; then
                        delete_generations "$profile" "$CHOSEN_GENERATIONS"
                        nix-collect-garbage
                    fi
                fi
            fi
            wait_key ;;
        opt)    optimize_store ;;
        clean)
            sudo nix-collect-garbage --delete-older-than 7d
            home-manager expire-generations "-7 days"
            sudo nix-store --optimise
            success "Cleanup complete."
            wait_key ;;
    esac
done
