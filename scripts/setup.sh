#!/usr/bin/env bash

# setup.sh - Interactive MD4N setup script

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
NC='\033[0m' # No Color

# --- Helper Functions ---
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${CYAN}==>${NC} ${BOLD}$1${NC}"; }
detail() { echo -e "   ${DIM:-}${1}${NC}"; }

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
    if [[ "${MD4N_CHAINED:-0}" != "1" ]]; then
        print_logo
    fi
    rule
    printf '%b%s%b\n' "${CYAN}${BOLD}" "                  SETUP CONSOLE                  " "${NC}"
    rule
    summary_row "Repository" "${ROOT_DIR}"
    summary_row "Previous" "install.sh -> bootstrap.sh"
    summary_row "Current" "setup.sh"
    summary_row "Next" "forge.sh (optional)"
    summary_row "Flow" "install.sh -> bootstrap.sh -> setup.sh"
    summary_row "user.nix" "${USER_NIX}"
    summary_row "local.nix" "${USER_LOCAL_NIX}"
    summary_row "Fish env" "${FISH_ENV_FILE}"
    rule
}

# Check if running in a terminal
is_interactive() {
    [[ -t 0 ]]
}

# --- Initialization & Pre-flight Checks ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NIX="${ROOT_DIR}/user.nix"
USER_LOCAL_NIX="${ROOT_DIR}/user.local.nix"
FORGE_SCRIPT="${ROOT_DIR}/scripts/forge.sh"
FISH_ENV_FILE="${ROOT_DIR}/home-manager/config/fish/conf.d/md4n-env.fish"

detect_locale() {
    local detected=""

    if command -v locale >/dev/null 2>&1; then
        detected=$(locale 2>/dev/null | awk -F= '/^LANG=/{gsub(/"/, "", $2); print $2; exit}')
    fi

    if [[ -z "$detected" && -n "${LANG:-}" ]]; then
        detected=${LANG}
    fi

    printf '%s\n' "${detected:-en_US.UTF-8}"
}

detect_timezone() {
    local detected=""

    if command -v timedatectl >/dev/null 2>&1; then
        detected=$(timedatectl show --property=Timezone --value 2>/dev/null || true)
    fi

    if [[ -z "$detected" && -f /etc/timezone ]]; then
        detected=$(head -n 1 /etc/timezone 2>/dev/null || true)
    fi

    if [[ -z "$detected" && -L /etc/localtime ]]; then
        detected=$(readlink /etc/localtime 2>/dev/null | sed 's#^.*/zoneinfo/##')
    fi

    printf '%s\n' "${detected:-Asia/Tokyo}"
}

detect_hostname() {
    local detected=""

    if command -v hostnamectl >/dev/null 2>&1; then
        detected=$(hostnamectl --static 2>/dev/null || true)
    fi

    if [[ -z "$detected" && -f /etc/hostname ]]; then
        detected=$(head -n 1 /etc/hostname 2>/dev/null || true)
    fi

    if [[ -z "$detected" && "$(command -v hostname || true)" ]]; then
        detected=$(hostname 2>/dev/null || true)
    fi

    printf '%s\n' "${detected:-nixos}"
}

detect_fullname() {
    local username=$1
    local gecos=""

    if command -v getent >/dev/null 2>&1; then
        gecos=$(getent passwd "$username" 2>/dev/null | cut -d ':' -f 5 | cut -d ',' -f 1 || true)
    fi

    if [[ -z "$gecos" && -r /etc/passwd ]]; then
        gecos=$(awk -F: -v user="$username" '$1 == user { split($5, fields, ","); print fields[1]; exit }' /etc/passwd 2>/dev/null || true)
    fi

    printf '%s\n' "${gecos:-User}"
}

detect_git_config() {
    local key=$1
    local detected=""

    if command -v git >/dev/null 2>&1; then
        detected=$(git config --global --get "$key" 2>/dev/null || true)
    elif has_nix; then
        warn "git is not available in PATH. Falling back to a temporary nix shell with git." >&2
        detected=$(run_nixpkgs_command git git config --global --get "$key" || true)
    fi

    printf '%s\n' "$detected"
}

has_nix() {
    command -v nix >/dev/null 2>&1
}

run_nixpkgs_command() {
    local package=$1
    shift

    if ! has_nix; then
        return 1
    fi

    nix shell "nixpkgs#${package}" --command "$@" 2>/dev/null
}

get_lspci_output() {
    if command -v lspci >/dev/null 2>&1; then
        lspci 2>/dev/null || true
        return 0
    fi

    if has_nix; then
        warn "lspci is not available in PATH. Falling back to a temporary nix shell with pciutils." >&2
        run_nixpkgs_command pciutils lspci || true
    fi
}

detect_gpu_vendor() {
    local detected=""
    local drm_vendor_file=""
    local drm_vendor_id=""
    local display_lines=""
    local lspci_output=""

    for drm_vendor_file in /sys/class/drm/card*/device/vendor; do
        if [[ ! -r "$drm_vendor_file" ]]; then
            continue
        fi

        drm_vendor_id=$(tr '[:upper:]' '[:lower:]' < "$drm_vendor_file" 2>/dev/null || true)
        case "$drm_vendor_id" in
            0x1002)
                detected="amd"
                break
                ;;
            0x10de)
                detected="nvidia"
                break
                ;;
            0x8086)
                detected="intel"
                break
                ;;
        esac
    done

    if [[ -n "$detected" ]]; then
        printf '%s\n' "$detected"
        return 0
    fi

    lspci_output=$(get_lspci_output)
    if [[ -n "$lspci_output" ]]; then
        display_lines=$(printf '%s\n' "$lspci_output" | grep -Ei 'vga|3d|display' || true)
        if [[ -n "$display_lines" ]]; then
            if printf '%s\n' "$display_lines" | grep -Eiq 'amd|advanced micro devices|ati|radeon'; then
                detected="amd"
            elif printf '%s\n' "$display_lines" | grep -Eiq 'nvidia'; then
                detected="nvidia"
            elif printf '%s\n' "$display_lines" | grep -Eiq 'intel'; then
                detected="intel"
            fi
        fi
    fi

    printf '%s\n' "${detected:-generic}"
}

print_dependency_status() {
    detail "Dependency checks:"

    if command -v git >/dev/null 2>&1; then
        detail "  - git     : available in PATH"
    elif has_nix; then
        detail "  - git     : missing in PATH, will use temporary nix shell if needed"
    else
        detail "  - git     : missing in PATH, Git defaults may be empty"
    fi

    if command -v lspci >/dev/null 2>&1; then
        detail "  - lspci   : available in PATH"
    elif has_nix; then
        detail "  - lspci   : missing in PATH, will use temporary nix shell if needed"
    else
        detail "  - lspci   : missing in PATH, GPU detection falls back to /sys/class/drm"
    fi

    if command -v getent >/dev/null 2>&1; then
        detail "  - getent  : available in PATH"
    else
        detail "  - getent  : missing in PATH, will read /etc/passwd directly"
    fi
}

normalize_gpu_vendor() {
    local value=$1

    value=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')

    case "$value" in
        amd|ati|radeon)
            printf 'amd'
            ;;
        nvidia)
            printf 'nvidia'
            ;;
        intel)
            printf 'intel'
            ;;
        generic|default|"")
            printf 'generic'
            ;;
        *)
            printf '%s' "$value"
            ;;
    esac
}

validate_locale() {
    [[ "$1" =~ ^[A-Za-z0-9_@.-]+$ ]]
}

validate_timezone() {
    [[ "$1" =~ ^[A-Za-z0-9_+\-]+(/[A-Za-z0-9_+\-]+)+$ ]]
}

validate_hostname() {
    [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]
}

validate_git_email() {
    [[ -z "$1" || "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

validate_package_profile() {
    [[ "$1" == "minimal" || "$1" == "full" || "$1" == "custom" || "$1" == "max" ]]
}

validate_gpu_vendor() {
    [[ "$1" == "amd" || "$1" == "nvidia" || "$1" == "intel" || "$1" == "generic" ]]
}

validate_bool_string() {
    [[ "$1" == "true" || "$1" == "false" ]]
}

escape_nix_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '%s' "$value"
}

render_nix_bool() {
    if [[ "$1" == "true" ]]; then
        printf 'true'
    else
        printf 'false'
    fi
}

print_package_profile_choices() {
    detail "Package profiles:"
    detail "  - minimal : lighter package set"
    detail "  - full    : default workstation profile"
    detail "  - custom  : full base intended for local tailoring"
    detail "  - max     : author's all-in profile, enables nearly everything"
}

print_gpu_vendor_choices() {
    detail "GPU vendor choices:"
    detail "  - amd     : enables ROCm variants for btop and ollama"
    detail "  - nvidia  : uses generic packages"
    detail "  - intel   : uses generic packages"
    detail "  - generic : fallback when vendor-specific handling is not wanted"
}

print_font_preferences_help() {
    detail "Custom font preferences only toggle the dedicated font module."
    detail "You are expected to fine-tune the actual font families later."
    detail "Edit: ${ROOT_DIR}/home-manager/modules/fonts.nix"
    detail "If you only want to turn the module on or off later, edit: ${ROOT_DIR}/user.local.nix"
}

print_virtualization_help() {
    detail "Virtualization environment:"
    detail "Enables Podman, libvirt, KVM group membership, and related desktop tools."
    detail "If disabled, virtualization modules and helper packages stay out of the system."
}

confirm_max_profile() {
    warn "The 'max' profile is the repository author's personal all-in setup."
    warn "It enables a large number of packages and settings, including many tools you may never use."
    read -p "Do you really want to apply the 'max' profile and skip the remaining optional prompts? [y/N] " confirm_max

    if [[ ! "$confirm_max" =~ ^[yY]$ ]]; then
        info "Max profile cancelled."
        exit 0
    fi
}

apply_max_profile_defaults() {
    enable_custom_fonts="true"
    enable_virtualization="true"
    enable_bcompare5="true"
    enable_vesktop="true"
    enable_cava="true"
    enable_gemini_cli="true"
    enable_codex="true"
    enable_claude_code="true"
    enable_google_chrome="true"
    enable_thunderbird="true"
    enable_obs_studio="true"
    enable_davinci_resolve="true"
    enable_zotero="true"
    enable_podman_desktop="true"
    enable_distrobox="true"
    enable_distroshelf="true"
    enable_texlive_full="true"
    enable_global_protect="true"
    enable_virt_manager="true"
    enable_ollama="true"
    enable_steam="true"
    gpu_vendor=$(normalize_gpu_vendor "$DEFAULT_GPU_VENDOR")
    enable_fingerprint="true"
    enable_dual_boot="true"
    enable_hibernate="false"
}

prompt_bool_with_default() {
    local prompt=$1
    local default_value=$2
    local answer=""

    if [[ "$default_value" == "true" ]]; then
        read -p "${prompt} [Y/n] " answer
        if [[ ! "$answer" =~ ^[nN]$ ]]; then
            printf 'true'
            return 0
        fi
    else
        read -p "${prompt} [y/N] " answer
        if [[ "$answer" =~ ^[yY]$ ]]; then
            printf 'true'
            return 0
        fi
    fi

    printf 'false'
}

prompt_optional_full_packages() {
    detail "Full profile optional packages:"
    detail "You will be asked about packages many users do not need."

    enable_bcompare5=$(prompt_bool_with_default "Include Beyond Compare 5 integration?" "true")
    detail "Google Chrome note: if you sign in with fprintd-based login, Chrome may still ask for your password."
    enable_google_chrome=$(prompt_bool_with_default "Include Google Chrome?" "true")
    enable_thunderbird=$(prompt_bool_with_default "Include Thunderbird?" "true")
    enable_obs_studio=$(prompt_bool_with_default "Include OBS Studio?" "true")
    enable_davinci_resolve=$(prompt_bool_with_default "Include DaVinci Resolve?" "true")
    enable_zotero=$(prompt_bool_with_default "Include Zotero?" "true")
    enable_podman_desktop=$(prompt_bool_with_default "Include Podman Desktop?" "true")
    enable_distrobox=$(prompt_bool_with_default "Include Distrobox?" "true")
    enable_distroshelf=$(prompt_bool_with_default "Include Distroshelf?" "true")
    enable_texlive_full=$(prompt_bool_with_default "Include TeX Live Full?" "true")
    enable_global_protect=$(prompt_bool_with_default "Include GlobalProtect OpenConnect?" "true")
    enable_virt_manager=$(prompt_bool_with_default "Include virt-manager and libvirt helper tools?" "true")
}

prompt_custom_profile_packages() {
    detail "Custom profile additions:"
    detail "You will be asked about apps and services that are outside the minimal baseline."

    enable_bcompare5=$(prompt_bool_with_default "Include Beyond Compare 5 integration?" "true")
    enable_vesktop=$(prompt_bool_with_default "Include Vesktop?" "true")
    enable_cava=$(prompt_bool_with_default "Include CAVA?" "true")
    enable_gemini_cli=$(prompt_bool_with_default "Include Gemini CLI?" "true")
    enable_codex=$(prompt_bool_with_default "Include Codex?" "true")
    enable_claude_code=$(prompt_bool_with_default "Include Claude Code?" "true")
    detail "Google Chrome note: if you sign in with fprintd-based login, Chrome may still ask for your password."
    enable_google_chrome=$(prompt_bool_with_default "Include Google Chrome?" "true")
    enable_thunderbird=$(prompt_bool_with_default "Include Thunderbird?" "true")
    enable_obs_studio=$(prompt_bool_with_default "Include OBS Studio?" "true")
    enable_davinci_resolve=$(prompt_bool_with_default "Include DaVinci Resolve?" "true")
    enable_zotero=$(prompt_bool_with_default "Include Zotero?" "true")
    enable_ollama=$(prompt_bool_with_default "Enable Ollama service?" "true")
    enable_steam=$(prompt_bool_with_default "Enable Steam?" "true")
    enable_texlive_full=$(prompt_bool_with_default "Include TeX Live Full?" "true")
    enable_global_protect=$(prompt_bool_with_default "Include GlobalProtect OpenConnect?" "true")

    if [[ "$enable_virtualization" == "true" ]]; then
        enable_podman_desktop=$(prompt_bool_with_default "Include Podman Desktop?" "true")
        enable_distrobox=$(prompt_bool_with_default "Include Distrobox?" "true")
        enable_distroshelf=$(prompt_bool_with_default "Include Distroshelf?" "true")
        enable_virt_manager=$(prompt_bool_with_default "Include virt-manager and libvirt helper tools?" "true")
    else
        detail "Virtualization environment disabled: skipping Podman, Distrobox, Distroshelf, and virt-manager prompts."
        enable_podman_desktop="false"
        enable_distrobox="false"
        enable_distroshelf="false"
        enable_virt_manager="false"
    fi
}

run_fingerprint_enroll() {
    local username=$1

    info "Starting fingerprint enrollment for ${username}."
    detail "If you prefer to do this later, run: fprintd-enroll ${username}"

    if command -v fprintd-enroll >/dev/null 2>&1; then
        fprintd-enroll "$username"
        return $?
    fi

    if has_nix; then
        warn "fprintd-enroll is not available in PATH. Falling back to a temporary nix shell with fprintd." >&2
        run_nixpkgs_command fprintd fprintd-enroll "$username"
        return $?
    fi

    warn "fprintd-enroll is not available. After applying the configuration, run: fprintd-enroll ${username}"
    return 1
}

render_fish_env() {
    local dotroot=$1

cat <<EOF
# Auto-generated by scripts/setup.sh
set -gx MD4N_ROOT "${dotroot}"
set -gx MD4N_SCRIPTS "\$MD4N_ROOT/scripts"
if not contains "\$MD4N_SCRIPTS" \$PATH
    fish_add_path --append "\$MD4N_SCRIPTS"
end
EOF
}

write_fish_env() {
    local dotroot=$1
    local new_content
    local action="overwrite"

    mkdir -p "$(dirname "$FISH_ENV_FILE")"
    new_content=$(render_fish_env "$dotroot")

    if [[ -f "$FISH_ENV_FILE" ]]; then
        if cmp -s "$FISH_ENV_FILE" <(printf '%s\n' "$new_content"); then
            info "Fish environment file is already up to date."
            return 0
        fi

        if is_interactive; then
            echo -e "${YELLOW}Existing Fish environment file found:${NC} ${FISH_ENV_FILE}"
            read -r -p "Overwrite it with the new MD4N environment settings, or keep the current file? [overwrite/keep] " action
            action=${action:-overwrite}
        else
            action="keep"
        fi

        case "$action" in
            overwrite)
                ;;
            keep)
                warn "Keeping existing Fish environment file unchanged."
                return 0
                ;;
            *)
                warn "Unknown choice: ${action}. Keeping existing Fish environment file unchanged."
                return 0
                ;;
        esac
    fi

    printf '%s\n' "$new_content" > "$FISH_ENV_FILE"
}

print_banner
info "Preparing MD4N configuration..."

# --- 0. Mode Selection ---
AUTO_MODE=false
FIRST_TIME=false
[[ -f "$USER_LOCAL_NIX" ]] || FIRST_TIME=true

if is_interactive && [[ "$AUTO_MODE" == "false" ]]; then
    echo
    if [[ "$FIRST_TIME" == "true" ]]; then
        warn "This is your first time running the setup."
        info "The automatic setup is mandatory for the initial configuration to ensure a correct baseline."
        read -p "Do you want to proceed with the automatic setup? [Y/n] " auto_confirm
        if [[ ! "$auto_confirm" =~ ^[yY]?$ ]]; then
            error "Setup cancelled. Automatic setup is required for the first run."
        fi
        AUTO_MODE=true
        success "Proceeding with automatic setup..."
    else
        read -p "Enable automatic setup? (Skips name/locale/timezone/hostname/Git/GPU/fingerprint/dual-boot prompts, but still asks about profile and optional packages) [y/N] " auto_confirm
        if [[ "$auto_confirm" =~ ^[yY]$ ]]; then
            AUTO_MODE=true
            info "Automatic mode enabled."
        fi
    fi
    echo
fi

# 1. Dependency Check
print_dependency_status

if [[ ! -f "${ROOT_DIR}/flake.nix" ]]; then
    error "Could not find flake.nix in ${ROOT_DIR}. Please run this script from the repository root."
fi

# 2. Existing Configuration Check (The Confirmation Request)
if [[ -f "$USER_LOCAL_NIX" ]] && is_interactive && [[ "$AUTO_MODE" == "false" ]]; then
    echo -e "${YELLOW}Existing user.local.nix found.${NC}"
    read -p "Do you really want to run the setup again? This will overwrite your settings. [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        info "Setup cancelled by user."
        exit 0
    fi
fi

# --- 1. User Configuration (user.local.nix) ---
step "Collecting user configuration"

dotroot="$ROOT_DIR"

username=$(whoami)
DEFAULT_FULLNAME=$(detect_fullname "$username")
DEFAULT_LOCALE=$(detect_locale)
DEFAULT_TIMEZONE=$(detect_timezone)
DEFAULT_HOSTNAME=$(detect_hostname)
DEFAULT_GIT_NAME=$(detect_git_config user.name)
DEFAULT_GIT_EMAIL=$(detect_git_config user.email)
DEFAULT_GPU_VENDOR=$(detect_gpu_vendor)

if [[ -z "$DEFAULT_GIT_NAME" ]]; then
    DEFAULT_GIT_NAME=$DEFAULT_FULLNAME
fi

if is_interactive && [[ "$AUTO_MODE" == "false" ]]; then
    info "Detected username: ${GREEN}${username}${NC}"

    read -p "Enter your full name [$DEFAULT_FULLNAME]: " fullname
    fullname=${fullname:-$DEFAULT_FULLNAME}

    read -p "Enter your system locale [$DEFAULT_LOCALE]: " locale_value
    locale_value=${locale_value:-$DEFAULT_LOCALE}

    if ! validate_locale "$locale_value"; then
        error "Invalid locale format: $locale_value"
    fi

    read -p "Enter your location/time zone [$DEFAULT_TIMEZONE]: " timezone_value
    timezone_value=${timezone_value:-$DEFAULT_TIMEZONE}

    if ! validate_timezone "$timezone_value"; then
        error "Invalid time zone format: $timezone_value"
    fi

    read -p "Enter your hostname [$DEFAULT_HOSTNAME]: " hostname_value
    hostname_value=${hostname_value:-$DEFAULT_HOSTNAME}

    if ! validate_hostname "$hostname_value"; then
        error "Invalid hostname format: $hostname_value"
    fi

    read -p "Enter your Git author name [$DEFAULT_GIT_NAME]: " git_name
    git_name=${git_name:-$DEFAULT_GIT_NAME}

    read -p "Enter your Git author email [$DEFAULT_GIT_EMAIL]: " git_email
    git_email=${git_email:-$DEFAULT_GIT_EMAIL}

    if ! validate_git_email "$git_email"; then
        error "Invalid Git email format: $git_email"
    fi

    if [[ -z "$git_email" ]]; then
        warn "Git email is empty. Home Manager will not set programs.git.settings.user.email."
    fi

    print_package_profile_choices
    read -p "Select your package profile [full]: " package_profile
    package_profile=${package_profile:-full}

    if ! validate_package_profile "$package_profile"; then
        error "Invalid package profile: $package_profile"
    fi

    if [[ "$package_profile" == "max" ]]; then
        confirm_max_profile
        apply_max_profile_defaults
    else
        print_font_preferences_help
        enable_custom_fonts=$(prompt_bool_with_default "Enable custom font preferences?" "false")

        enable_virtualization="true"
        if [[ "$package_profile" != "minimal" ]]; then
            print_virtualization_help
            enable_virtualization=$(prompt_bool_with_default "Enable virtualization environment?" "true")
        fi

        enable_bcompare5="true"
        enable_vesktop="true"
        enable_cava="true"
        enable_gemini_cli="true"
        enable_codex="true"
        enable_claude_code="true"
        enable_google_chrome="true"
        enable_thunderbird="true"
        enable_obs_studio="true"
        enable_davinci_resolve="true"
        enable_zotero="true"
        enable_podman_desktop="true"
        enable_distrobox="true"
        enable_distroshelf="true"
        enable_texlive_full="true"
        enable_global_protect="true"
        enable_virt_manager="true"
        enable_ollama="true"
        enable_steam="true"

        if [[ "$package_profile" == "full" ]]; then
            if [[ "$enable_virtualization" == "true" ]]; then
                prompt_optional_full_packages
            else
                detail "Virtualization environment disabled: skipping Podman, Distrobox, Distroshelf, and virt-manager prompts."
                enable_bcompare5=$(prompt_bool_with_default "Include Beyond Compare 5 integration?" "true")
                detail "Google Chrome note: if you sign in with fprintd-based login, Chrome may still ask for your password."
                enable_google_chrome=$(prompt_bool_with_default "Include Google Chrome?" "true")
                enable_thunderbird=$(prompt_bool_with_default "Include Thunderbird?" "true")
                enable_obs_studio=$(prompt_bool_with_default "Include OBS Studio?" "true")
                enable_davinci_resolve=$(prompt_bool_with_default "Include DaVinci Resolve?" "true")
                enable_zotero=$(prompt_bool_with_default "Include Zotero?" "true")
                enable_texlive_full=$(prompt_bool_with_default "Include TeX Live Full?" "true")
                enable_global_protect=$(prompt_bool_with_default "Include GlobalProtect OpenConnect?" "true")
                enable_podman_desktop="false"
                enable_distrobox="false"
                enable_distroshelf="false"
                enable_virt_manager="false"
            fi
        elif [[ "$package_profile" == "custom" ]]; then
            prompt_custom_profile_packages
        elif [[ "$package_profile" == "minimal" ]]; then
            enable_bcompare5="false"
            enable_vesktop="false"
            enable_cava="false"
            enable_gemini_cli="false"
            enable_codex="false"
            enable_claude_code="false"
            enable_google_chrome="false"
            enable_thunderbird="false"
            enable_obs_studio="false"
            enable_davinci_resolve="false"
            enable_zotero="false"
            enable_podman_desktop="false"
            enable_distrobox="false"
            enable_distroshelf="false"
            enable_texlive_full="false"
            enable_global_protect="false"
            enable_virtualization="false"
            enable_virt_manager="false"
            enable_ollama="false"
            enable_steam="false"
        elif [[ "$enable_virtualization" != "true" ]]; then
            enable_podman_desktop="false"
            enable_distrobox="false"
            enable_distroshelf="false"
            enable_virt_manager="false"
        fi

        print_gpu_vendor_choices
        read -p "Enter your GPU vendor [$DEFAULT_GPU_VENDOR]: " gpu_vendor
        gpu_vendor=${gpu_vendor:-$DEFAULT_GPU_VENDOR}
        gpu_vendor=$(normalize_gpu_vendor "$gpu_vendor")

        if ! validate_gpu_vendor "$gpu_vendor"; then
            error "Invalid GPU vendor: $gpu_vendor"
        fi

        read -p "Enable fingerprint authentication? [y/N] " enable_fingerprint_confirm
        if [[ "$enable_fingerprint_confirm" =~ ^[yY]$ ]]; then
            enable_fingerprint="true"
            detail "Fingerprint enrollment command: fprintd-enroll ${username}"
        else
            enable_fingerprint="false"
        fi

        read -p "Enable dual-boot support (GRUB os-prober)? [y/N] " enable_dual_boot_confirm
        if [[ "$enable_dual_boot_confirm" =~ ^[yY]$ ]]; then
            enable_dual_boot="true"
            enable_hibernate="false"
            info "Dual-boot support enabled. Hibernate is forced off to avoid resume conflicts."
        else
            enable_dual_boot="false"
            read -p "Enable hibernate and hybrid-sleep? [y/N] " enable_hibernate_confirm
            if [[ "$enable_hibernate_confirm" =~ ^[yY]$ ]]; then
                enable_hibernate="true"
            else
                enable_hibernate="false"
            fi
        fi
    fi

    echo
    info "Review your MD4N settings."
    detail "Username : ${username}"
    detail "Full name: ${fullname}"
    detail "Locale   : ${locale_value}"
    detail "Timezone : ${timezone_value}"
    detail "Hostname : ${hostname_value}"
    detail "Git name : ${git_name}"
    detail "Git email: ${git_email:-<unset>}"
    detail "Profile  : ${package_profile}"
    detail "Fonts    : ${enable_custom_fonts}"
    detail "BCompare : ${enable_bcompare5}"
    detail "Vesktop  : ${enable_vesktop}"
    detail "CAVA     : ${enable_cava}"
    detail "Gemini   : ${enable_gemini_cli}"
    detail "Codex    : ${enable_codex}"
    detail "Claude   : ${enable_claude_code}"
    detail "Chrome   : ${enable_google_chrome}"
    detail "Mail     : ${enable_thunderbird}"
    detail "OBS      : ${enable_obs_studio}"
    detail "Resolve  : ${enable_davinci_resolve}"
    detail "Zotero   : ${enable_zotero}"
    detail "Podman UI: ${enable_podman_desktop}"
    detail "Distrobox: ${enable_distrobox}"
    detail "Shelf    : ${enable_distroshelf}"
    detail "TeX Live : ${enable_texlive_full}"
    detail "GP VPN   : ${enable_global_protect}"
    detail "Virtual  : ${enable_virtualization}"
    detail "Virt Mgr : ${enable_virt_manager}"
    detail "Ollama   : ${enable_ollama}"
    detail "Steam    : ${enable_steam}"
    detail "GPU      : ${gpu_vendor}"
    detail "Fingerprint: ${enable_fingerprint}"
    detail "Dualboot : ${enable_dual_boot}"
    detail "Hibernate: ${enable_hibernate}"
    detail "Dotfiles : ${dotroot}"
else
    # Automatic or non-interactive defaults
    if [[ "$AUTO_MODE" == "true" ]]; then
        info "Automatic mode: using detected values and repository defaults."
        print_package_profile_choices
        read -p "Select your package profile [full]: " package_profile
        package_profile=${package_profile:-full}

        if ! validate_package_profile "$package_profile"; then
            error "Invalid package profile: $package_profile"
        fi

        if [[ "$package_profile" == "max" ]]; then
            confirm_max_profile
        fi
    else
        package_profile="full"
    fi

    fullname=$DEFAULT_FULLNAME
    locale_value=$DEFAULT_LOCALE
    timezone_value=$DEFAULT_TIMEZONE
    hostname_value=$DEFAULT_HOSTNAME
    git_name=${DEFAULT_GIT_NAME:-$DEFAULT_FULLNAME}
    git_email=$DEFAULT_GIT_EMAIL
    enable_custom_fonts="false"
    enable_bcompare5="true"
    enable_vesktop="true"
    enable_cava="true"
    enable_gemini_cli="true"
    enable_codex="true"
    enable_claude_code="true"
    enable_google_chrome="true"
    enable_thunderbird="true"
    enable_obs_studio="true"
    enable_davinci_resolve="true"
    enable_zotero="true"
    enable_podman_desktop="true"
    enable_distrobox="true"
    enable_distroshelf="true"
    enable_texlive_full="true"
    enable_global_protect="true"
    enable_virtualization="true"
    enable_virt_manager="true"
    enable_ollama="true"
    enable_steam="true"
    gpu_vendor=$(normalize_gpu_vendor "$DEFAULT_GPU_VENDOR")
    enable_fingerprint="false"
    enable_dual_boot="false"
    enable_hibernate="false"

    if [[ "$package_profile" == "minimal" ]]; then
        enable_bcompare5="false"
        enable_vesktop="false"
        enable_cava="false"
        enable_gemini_cli="false"
        enable_codex="false"
        enable_claude_code="false"
        enable_google_chrome="false"
        enable_thunderbird="false"
        enable_obs_studio="false"
        enable_davinci_resolve="false"
        enable_zotero="false"
        enable_virtualization="false"
        enable_podman_desktop="false"
        enable_distrobox="false"
        enable_distroshelf="false"
        enable_virt_manager="false"
        enable_texlive_full="false"
        enable_global_protect="false"
        enable_ollama="false"
        enable_steam="false"
    elif [[ "$AUTO_MODE" == "true" && "$package_profile" != "max" ]]; then
        print_virtualization_help
        enable_virtualization=$(prompt_bool_with_default "Enable virtualization environment?" "true")

        if [[ "$enable_virtualization" != "true" ]]; then
            enable_podman_desktop="false"
            enable_distrobox="false"
            enable_distroshelf="false"
            enable_virt_manager="false"
        fi

        if [[ "$package_profile" == "full" ]]; then
            prompt_optional_full_packages

            if [[ "$enable_virtualization" != "true" ]]; then
                enable_podman_desktop="false"
                enable_distrobox="false"
                enable_distroshelf="false"
                enable_virt_manager="false"
            fi
        elif [[ "$package_profile" == "custom" ]]; then
            prompt_custom_profile_packages
        fi
    elif [[ "$package_profile" == "max" ]]; then
        apply_max_profile_defaults
    fi
fi

if ! validate_bool_string "$enable_fingerprint"; then
    error "Invalid fingerprint flag: $enable_fingerprint"
fi

if ! validate_bool_string "$enable_bcompare5"; then
    error "Invalid Beyond Compare flag: $enable_bcompare5"
fi

if ! validate_bool_string "$enable_vesktop"; then
    error "Invalid Vesktop flag: $enable_vesktop"
fi

if ! validate_bool_string "$enable_cava"; then
    error "Invalid CAVA flag: $enable_cava"
fi

if ! validate_bool_string "$enable_gemini_cli"; then
    error "Invalid Gemini CLI flag: $enable_gemini_cli"
fi

if ! validate_bool_string "$enable_codex"; then
    error "Invalid Codex flag: $enable_codex"
fi

if ! validate_bool_string "$enable_claude_code"; then
    error "Invalid Claude Code flag: $enable_claude_code"
fi

if ! validate_bool_string "$enable_google_chrome"; then
    error "Invalid Google Chrome flag: $enable_google_chrome"
fi

if ! validate_bool_string "$enable_thunderbird"; then
    error "Invalid Thunderbird flag: $enable_thunderbird"
fi

if ! validate_bool_string "$enable_obs_studio"; then
    error "Invalid OBS Studio flag: $enable_obs_studio"
fi

if ! validate_bool_string "$enable_davinci_resolve"; then
    error "Invalid DaVinci Resolve flag: $enable_davinci_resolve"
fi

if ! validate_bool_string "$enable_zotero"; then
    error "Invalid Zotero flag: $enable_zotero"
fi

if ! validate_bool_string "$enable_podman_desktop"; then
    error "Invalid Podman Desktop flag: $enable_podman_desktop"
fi

if ! validate_bool_string "$enable_distrobox"; then
    error "Invalid Distrobox flag: $enable_distrobox"
fi

if ! validate_bool_string "$enable_distroshelf"; then
    error "Invalid Distroshelf flag: $enable_distroshelf"
fi

if ! validate_bool_string "$enable_texlive_full"; then
    error "Invalid TeX Live flag: $enable_texlive_full"
fi

if ! validate_bool_string "$enable_global_protect"; then
    error "Invalid GlobalProtect flag: $enable_global_protect"
fi

if ! validate_bool_string "$enable_virtualization"; then
    error "Invalid virtualization flag: $enable_virtualization"
fi

if ! validate_bool_string "$enable_virt_manager"; then
    error "Invalid virt-manager flag: $enable_virt_manager"
fi

if ! validate_bool_string "$enable_ollama"; then
    error "Invalid Ollama flag: $enable_ollama"
fi

if ! validate_bool_string "$enable_steam"; then
    error "Invalid Steam flag: $enable_steam"
fi

if ! validate_bool_string "$enable_dual_boot"; then
    error "Invalid dual-boot flag: $enable_dual_boot"
fi

if ! validate_bool_string "$enable_hibernate"; then
    error "Invalid hibernate flag: $enable_hibernate"
fi

# Backup existing user.local.nix
if [[ -f "$USER_LOCAL_NIX" ]]; then
    warn "Creating backup of user.local.nix..."
    mv "$USER_LOCAL_NIX" "${USER_LOCAL_NIX}.bak"
    detail "Backup path: ${USER_LOCAL_NIX}.bak"
fi

info "Generating user.local.nix..."
cat <<EOF > "$USER_LOCAL_NIX"
# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
# user.local.nix - Auto-generated by setup.sh

let
  name = "$(escape_nix_string "$username")";
  fullname = "$(escape_nix_string "$fullname")";
  locale = "$(escape_nix_string "$locale_value")";
  timezone = "$(escape_nix_string "$timezone_value")";
  hostname = "$(escape_nix_string "$hostname_value")";
  gitName = "$(escape_nix_string "$git_name")";
  gitEmail = "$(escape_nix_string "$git_email")";
  packageProfile = "$(escape_nix_string "$package_profile")";
  enableCustomFonts = $(render_nix_bool "$enable_custom_fonts");
  enableBcompare5 = $(render_nix_bool "$enable_bcompare5");
  enableVesktop = $(render_nix_bool "$enable_vesktop");
  enableCava = $(render_nix_bool "$enable_cava");
  enableGeminiCli = $(render_nix_bool "$enable_gemini_cli");
  enableCodex = $(render_nix_bool "$enable_codex");
  enableClaudeCode = $(render_nix_bool "$enable_claude_code");
  enableGoogleChrome = $(render_nix_bool "$enable_google_chrome");
  enableThunderbird = $(render_nix_bool "$enable_thunderbird");
  enableObsStudio = $(render_nix_bool "$enable_obs_studio");
  enableDavinciResolve = $(render_nix_bool "$enable_davinci_resolve");
  enableZotero = $(render_nix_bool "$enable_zotero");
  enablePodmanDesktop = $(render_nix_bool "$enable_podman_desktop");
  enableDistrobox = $(render_nix_bool "$enable_distrobox");
  enableDistroshelf = $(render_nix_bool "$enable_distroshelf");
  enableTexliveFull = $(render_nix_bool "$enable_texlive_full");
  enableGlobalProtect = $(render_nix_bool "$enable_global_protect");
  enableVirtualization = $(render_nix_bool "$enable_virtualization");
  enableVirtManager = $(render_nix_bool "$enable_virt_manager");
  enableOllama = $(render_nix_bool "$enable_ollama");
  enableSteam = $(render_nix_bool "$enable_steam");
  gpuVendor = "$(escape_nix_string "$gpu_vendor")";
  enableFingerprint = $(render_nix_bool "$enable_fingerprint");
  enableDualBoot = $(render_nix_bool "$enable_dual_boot");
  enableHibernate = $(render_nix_bool "$enable_hibernate");
  home = "/home/\${name}";
  dotroot = "$(escape_nix_string "$dotroot")";
  homemanager = "\${dotroot}/home-manager";
  cfg = "\${homemanager}/config";
  app = "\${homemanager}/applications";
in
{
  inherit name fullname locale timezone hostname gitName gitEmail packageProfile enableCustomFonts enableBcompare5 enableVesktop enableCava enableGeminiCli enableCodex enableClaudeCode enableGoogleChrome enableThunderbird enableObsStudio enableDavinciResolve enableZotero enablePodmanDesktop enableDistrobox enableDistroshelf enableTexliveFull enableGlobalProtect enableVirtualization enableVirtManager enableOllama enableSteam gpuVendor enableFingerprint enableDualBoot enableHibernate home dotroot homemanager cfg app;
}
EOF

success "Created ${USER_LOCAL_NIX}"

step "Writing shell environment"
detail "Exports MD4N_ROOT and MD4N_SCRIPTS"
detail "Adds scripts/ to Fish PATH"
write_fish_env "$dotroot"
success "Fish environment setup finished for ${FISH_ENV_FILE}"

# --- 2. Hardware Configuration ---
step "Preparing hardware configuration"
TARGET_HW_CONFIG="${ROOT_DIR}/nixos/hardware-configuration.nix"
TARGET_HW_CONFIG_BAK="${TARGET_HW_CONFIG}.bak"

if is_interactive && [[ "$AUTO_MODE" == "false" ]]; then
    read -p "Would you like to generate a new hardware configuration for THIS machine? (Requires sudo) [y/N] " gen_hw
    if [[ "$gen_hw" =~ ^[yY]$ ]]; then
        if [[ -e "${TARGET_HW_CONFIG}" || -L "${TARGET_HW_CONFIG}" ]]; then
            warn "Backing up existing hardware configuration..."
            mv "${TARGET_HW_CONFIG}" "${TARGET_HW_CONFIG_BAK}"
            detail "Backup path: ${TARGET_HW_CONFIG_BAK}"
        fi
        info "Generating hardware configuration at ${TARGET_HW_CONFIG}..."
        sudo nixos-generate-config --show-hardware-config > "${TARGET_HW_CONFIG}"
        success "Generated hardware configuration."
    else
        warn "Skipped hardware configuration generation."
    fi
elif [[ "$AUTO_MODE" == "true" ]]; then
    if [[ ! -f "${TARGET_HW_CONFIG}" ]] || [[ "$FIRST_TIME" == "true" ]]; then
        info "Automatic mode: Generating hardware configuration..."
        if [[ -e "${TARGET_HW_CONFIG}" || -L "${TARGET_HW_CONFIG}" ]]; then
            mv "${TARGET_HW_CONFIG}" "${TARGET_HW_CONFIG_BAK}"
        fi
        sudo nixos-generate-config --show-hardware-config > "${TARGET_HW_CONFIG}"
        success "Generated hardware configuration."
    else
        info "Automatic mode: Skipping hardware configuration generation (already exists)."
    fi
fi

# --- 3. Finalization ---
step "Final step"
detail "You can manage your system with mn.sh or forge.sh."

if [[ "$AUTO_MODE" == "true" ]]; then
    info "Automatic mode: Applying configuration with the detected/default setup."
    detail "NixOS target : ${hostname_value}"
    detail "Home target  : ${username}"
    detail "Profile      : ${package_profile}"
    detail "Virtual      : ${enable_virtualization}"
    detail "Fingerprint  : ${enable_fingerprint}"
    detail "This will run: sudo nixos-rebuild switch --flake path:${ROOT_DIR}#${hostname_value}"
    detail "Then it will run: home-manager switch -b md4nbak --flake path:${ROOT_DIR}#${username}"
    
    # Refresh sudo credentials
    sudo -v
    
    # 1. Apply NixOS
    info "Applying NixOS configuration..."
    sudo nixos-rebuild switch --flake "path:${ROOT_DIR}#${hostname_value}"
    
    # 2. Apply Home Manager
    info "Applying Home Manager configuration..."
    home-manager switch -b md4nbak --flake "path:${ROOT_DIR}#${username}"
    
    success "Configuration applied successfully."

    if is_interactive && [[ "$enable_fingerprint" == "true" ]]; then
        info "Fingerprint authentication is enabled in the generated configuration."
        detail "If you continue, setup will launch: fprintd-enroll ${username}"
        read -p "Enroll a fingerprint now? [y/N] " enroll_fingerprint_now
        if [[ "$enroll_fingerprint_now" =~ ^[yY]$ ]]; then
            run_fingerprint_enroll "$username" || warn "Fingerprint enrollment did not complete. You can retry later with: fprintd-enroll ${username}"
        fi
    fi
elif is_interactive; then
    read -p "Would you like to apply the configuration now? (This will run forge.sh) [y/N] " apply_conf
    if [[ "$apply_conf" =~ ^[yY]$ ]]; then
        [[ -f "$FORGE_SCRIPT" ]] || error "Could not find forge.sh at ${FORGE_SCRIPT}"
        info "Running: bash ${FORGE_SCRIPT}"
        bash "$FORGE_SCRIPT"

        if [[ "$enable_fingerprint" == "true" ]]; then
            info "Fingerprint authentication is enabled in the generated configuration."
            detail "If you continue, setup will launch: fprintd-enroll ${username}"
            read -p "Enroll a fingerprint now? [y/N] " enroll_fingerprint_now
            if [[ "$enroll_fingerprint_now" =~ ^[yY]$ ]]; then
                run_fingerprint_enroll "$username" || warn "Fingerprint enrollment did not complete. You can retry later with: fprintd-enroll ${username}"
            fi
        fi
    else
        info "Next steps (manual):"
        echo -e "  1. Edit ${YELLOW}user.nix${NC} if needed."
        echo -e "  2. Run: ${YELLOW}bash scripts/mn.sh${NC} for the control center."
        echo -e "  3. Or run: ${YELLOW}bash ${FORGE_SCRIPT}${NC} to apply changes directly."
        if [[ "$enable_fingerprint" == "true" ]]; then
            echo -e "  4. After applying, run: ${YELLOW}fprintd-enroll ${username}${NC}"
        fi
    fi
fi

echo -e "\n${GREEN}Setup finished successfully!${NC}"
echo -e "\n${BLUE}Happy Hacking!${NC}"
