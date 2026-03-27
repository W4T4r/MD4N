#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_ROOT="$SCRIPT_DIR"
STATE_ROOT="${HOME}/.local/state/md4n-private-links"

LOCAL_MANAGED_FILES=(
    "README.md"
    "flake.lock"
    "flake.nix"
    "generated/user.nix"
    "home-manager/default.nix"
    "home-manager/extra-modules.nix"
    "home-manager/fonts.nix"
    "home-manager/packages.nix"
    "home-manager/programs.nix"
    "home-manager/services.nix"
    "nixos/default.nix"
    "nixos/extra-modules.nix"
    "nixos/packages.nix"
    "nixos/services.nix"
    "nixos/swap.nix"
)

resolve_md4n_root() {
    local override=${1:-}

    if [[ -n "$override" ]]; then
        printf '%s\n' "$override"
        return 0
    fi

    if [[ -d "${PRIVATE_ROOT}/../MD4N/.git" ]]; then
        printf '%s\n' "$(cd "${PRIVATE_ROOT}/../MD4N" && pwd)"
        return 0
    fi

    if [[ -d "${HOME}/Documents/MD4N/.git" ]]; then
        printf '%s\n' "${HOME}/Documents/MD4N"
        return 0
    fi

    printf '%s\n' ""
}

backup_path() {
    local source=$1
    local label=$2
    local stamp backup

    stamp=$(date +%Y%m%d%H%M%S)
    backup="${STATE_ROOT}/$(basename "$source").${stamp}.bak"
    mkdir -p "$STATE_ROOT"
    echo "[WARN] Backing up ${label}: ${source} -> ${backup}"
    mv "$source" "$backup"
}

same_target() {
    local link_path=$1
    local target_path=$2
    [[ -L "$link_path" ]] || return 1
    [[ "$(readlink -f "$link_path" 2>/dev/null || true)" == "$(readlink -f "$target_path" 2>/dev/null || true)" ]]
}

seed_tree_if_missing() {
    local source=$1
    local target=$2

    if [[ -d "$source" ]]; then
        mkdir -p "$target"
        cp -an "$source/." "$target/"
    elif [[ -f "$source" && ! -e "$target" ]]; then
        mkdir -p "$(dirname "$target")"
        cp -a "$source" "$target"
    fi
}

ensure_file_if_missing() {
    local target=$1
    local content=$2

    if [[ ! -e "$target" ]]; then
        mkdir -p "$(dirname "$target")"
        printf '%s\n' "$content" > "$target"
    fi
}

migrate_file_if_missing_target() {
    local old_path=$1
    local new_path=$2
    local label=$3

    if [[ -e "$old_path" && ! -e "$new_path" ]]; then
        mkdir -p "$(dirname "$new_path")"
        mv "$old_path" "$new_path"
        echo "[INFO] Migrated ${label}: ${old_path} -> ${new_path}"
    fi
}

seed_matching_files_if_missing() {
    local source_dir=$1
    local target_dir=$2
    local pattern=$3
    local rel

    [[ -d "$source_dir" ]] || return 0

    mkdir -p "$target_dir"

    while IFS= read -r rel; do
        seed_tree_if_missing "${source_dir}/${rel}" "${target_dir}/${rel}"
    done < <(cd "$source_dir" && find . -maxdepth 1 -type f -name "$pattern" -printf '%P\n' | sort)
}

ensure_real_dir() {
    local path=$1
    local label=$2

    if [[ -L "$path" ]]; then
        backup_path "$path" "$label"
    elif [[ -e "$path" && ! -d "$path" ]]; then
        backup_path "$path" "$label"
    fi

    mkdir -p "$path"
}

link_path() {
    local link_path=$1
    local target_path=$2
    local label=$3

    mkdir -p "$(dirname "$target_path")"
    if same_target "$link_path" "$target_path"; then
        return 0
    fi

    if [[ -L "$link_path" ]]; then
        rm -f "$link_path"
    elif [[ -e "$link_path" ]]; then
        backup_path "$link_path" "$label"
    fi

    mkdir -p "$(dirname "$link_path")"
    ln -s "$target_path" "$link_path"
    echo "[INFO] Linked ${link_path} -> ${target_path}"
}

sync_file() {
    local source_path=$1
    local target_path=$2
    local label=$3

    mkdir -p "$(dirname "$target_path")"

    if [[ -L "$target_path" ]]; then
        rm -f "$target_path"
    elif [[ -e "$target_path" && ! -f "$target_path" ]]; then
        backup_path "$target_path" "$label"
    fi

    cp -a --remove-destination "$source_path" "$target_path"
    echo "[INFO] Synced ${target_path} <= ${source_path}"
}

link_tree_contents() {
    local source_root=$1
    local target_root=$2
    local label_prefix=$3
    local rel source_path target_path

    [[ -d "$source_root" ]] || return 0
    ensure_real_dir "$target_root" "$label_prefix root"

    while IFS= read -r rel; do
        source_path="${source_root}/${rel}"
        target_path="${target_root}/${rel}"
        link_path "$target_path" "$source_path" "${label_prefix} ${rel}"
    done < <(cd "$source_root" && find . -mindepth 1 \( -type f -o -type l \) -printf '%P\n' | sort)
}

ensure_md4n_local_layout() {
    local md4n_root=$1

    ensure_real_dir "${md4n_root}/local" "local root"
    ensure_real_dir "${md4n_root}/local/generated" "local generated root"
    ensure_real_dir "${md4n_root}/local/home-manager" "local home-manager root"
    ensure_real_dir "${md4n_root}/local/nixos" "local nixos root"
}

seed_local_override_files() {
    local md4n_root=$1
    local machine_root=$2
    local rel

    mkdir -p "${machine_root}/local/generated" "${machine_root}/local/home-manager" "${machine_root}/local/nixos"

    for rel in "${LOCAL_MANAGED_FILES[@]}"; do
        seed_tree_if_missing "${md4n_root}/local/${rel}" "${machine_root}/local/${rel}"
    done
}

sync_local_override_files() {
    local machine_root=$1
    local md4n_root=$2
    local rel

    ensure_md4n_local_layout "$md4n_root"

    for rel in "${LOCAL_MANAGED_FILES[@]}"; do
        if [[ -f "${machine_root}/local/${rel}" || -L "${machine_root}/local/${rel}" ]]; then
            sync_file "${machine_root}/local/${rel}" "${md4n_root}/local/${rel}" "local ${rel}"
        fi
    done
}

ensure_private_niri_layout() {
    local machine_root=$1
    local md4n_root=$2
    local private_niri_root="${machine_root}/home-manager/niri"
    local md4n_niri_root="${md4n_root}/home-manager/config/niri"

    mkdir -p "${private_niri_root}/local"

    migrate_file_if_missing_target \
        "${private_niri_root}/outputs.local.kdl" \
        "${private_niri_root}/outputs.kdl" \
        "niri outputs"

    seed_tree_if_missing "${md4n_niri_root}/outputs.kdl" "${private_niri_root}/outputs.kdl"
    seed_tree_if_missing "${md4n_niri_root}/outputs.local.kdl" "${private_niri_root}/outputs.kdl"
    seed_tree_if_missing "${md4n_niri_root}/config.local.kdl" "${private_niri_root}/config.local.kdl"
    seed_matching_files_if_missing "${md4n_niri_root}/local" "${private_niri_root}/local" '*.local.kdl'

    ensure_file_if_missing "${private_niri_root}/config.local.kdl" '// Machine-local Niri overrides loaded last by config.kdl.
// Use this file to override the shared config without editing tracked KDL files.
// You can also split local-only snippets into local/*.local.kdl and include them here.
//
// Example:
// include "local/laptop.local.kdl"'
}

list_machine_dirs() {
    find "$PRIVATE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name '.*' -printf '%f\n' | sort
}

choose_machine_dir() {
    local requested=${1:-}
    local reply i
    local -a machine_dirs

    mapfile -t machine_dirs < <(list_machine_dirs)
    [[ ${#machine_dirs[@]} -gt 0 ]] || { echo "[ERROR] No machine directories found in ${PRIVATE_ROOT}" >&2; exit 1; }

    if [[ -n "$requested" ]]; then
        for i in "${!machine_dirs[@]}"; do
            if [[ "${machine_dirs[$i]}" == "$requested" ]]; then
                printf '%s\n' "$requested"
                return 0
            fi
        done
        echo "[ERROR] Unknown machine config: ${requested}" >&2
        exit 1
    fi

    {
        echo "Available machine configs:"
        for i in "${!machine_dirs[@]}"; do
            printf '  %d. %s\n' "$((i + 1))" "${machine_dirs[$i]}"
        done
    } >&2

    read -r -p "Select machine config [1]: " reply
    reply=${reply:-1}
    [[ "$reply" =~ ^[0-9]+$ ]] || { echo "[ERROR] Invalid selection: ${reply}" >&2; exit 1; }
    (( reply >= 1 && reply <= ${#machine_dirs[@]} )) || { echo "[ERROR] Selection out of range: ${reply}" >&2; exit 1; }

    printf '%s\n' "${machine_dirs[$((reply - 1))]}"
}

usage() {
    cat <<'EOF_USAGE'
Usage: bash ./link-md4n.sh [--md4n-root /path/to/MD4N] [--machine machine-dir]

Without --machine, the script lists top-level machine directories in this private
repository and asks which one to apply.

Local flake files are synced into MD4N/local so Nix can evaluate them safely.
Local linking excludes generated hardware files such as:
- local/nixos/hardware.nix
EOF_USAGE
}

main() {
    local md4n_root_override=""
    local requested_machine=""
    local md4n_root machine_dir machine_root

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --md4n-root)
                md4n_root_override=${2:-}
                shift 2
                ;;
            --machine)
                requested_machine=${2:-}
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "[ERROR] Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    md4n_root=$(resolve_md4n_root "$md4n_root_override")
    [[ -n "$md4n_root" ]] || { echo "[ERROR] Could not resolve MD4N root." >&2; exit 1; }
    [[ -d "$md4n_root/.git" ]] || { echo "[ERROR] Invalid MD4N root: ${md4n_root}" >&2; exit 1; }

    machine_dir=$(choose_machine_dir "$requested_machine")
    machine_root="${PRIVATE_ROOT}/${machine_dir}"

    mkdir -p \
        "${machine_root}/local/generated" \
        "${machine_root}/local/home-manager" \
        "${machine_root}/local/nixos" \
        "${machine_root}/home-manager/btop" \
        "${machine_root}/home-manager/custom-fonts" \
        "${machine_root}/home-manager/fish" \
        "${machine_root}/home-manager/niri" \
        "${machine_root}/home-manager/niri/local"

    seed_local_override_files "$md4n_root" "$machine_root"
    seed_tree_if_missing "${md4n_root}/home-manager/config/btop" "${machine_root}/home-manager/btop"
    seed_tree_if_missing "${md4n_root}/home-manager/config/custom-fonts/fcitx5-classicui.conf" "${machine_root}/home-manager/custom-fonts/fcitx5-classicui.conf"
    seed_tree_if_missing "${md4n_root}/home-manager/config/custom-fonts/gtk-3.0-settings.ini" "${machine_root}/home-manager/custom-fonts/gtk-3.0-settings.ini"
    seed_tree_if_missing "${md4n_root}/home-manager/config/custom-fonts/gtk-4.0-settings.ini" "${machine_root}/home-manager/custom-fonts/gtk-4.0-settings.ini"
    seed_tree_if_missing "${md4n_root}/home-manager/config/niri/browser.sh" "${machine_root}/home-manager/niri/browser.sh"
    seed_tree_if_missing "${md4n_root}/home-manager/config/fish/local.env.fish" "${machine_root}/home-manager/fish/local.env.fish"
    seed_tree_if_missing "${md4n_root}/home-manager/config/fish/local.aliases.fish" "${machine_root}/home-manager/fish/local.aliases.fish"
    seed_tree_if_missing "${md4n_root}/home-manager/config/fish/local.functions.fish" "${machine_root}/home-manager/fish/local.functions.fish"

    ensure_file_if_missing "${machine_root}/home-manager/fish/local.env.fish" "# Local environment variables."
    ensure_file_if_missing "${machine_root}/home-manager/fish/local.aliases.fish" "# Local aliases and abbreviations."
    ensure_file_if_missing "${machine_root}/home-manager/fish/local.functions.fish" "# Local Fish functions."
    ensure_private_niri_layout "$machine_root" "$md4n_root"

    sync_local_override_files "$machine_root" "$md4n_root"
    link_tree_contents "${machine_root}/home-manager/custom-fonts" "${md4n_root}/home-manager/config/custom-fonts" "custom-fonts"
    link_tree_contents "${machine_root}/home-manager/fish" "${md4n_root}/home-manager/config/fish" "fish"
    link_tree_contents "${machine_root}/home-manager/niri" "${md4n_root}/home-manager/config/niri" "niri"

    echo "[SUCCESS] Applied machine config: ${machine_dir}"
}

main "$@"
