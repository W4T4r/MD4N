#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/display-config.sh"

usage() {
    cat <<'EOF'
Usage: bash scripts/configure-niri-outputs.sh [--user USERNAME] [--output-file PATH] [--yes]

Detect connected DRM outputs and update ~/.config/niri/outputs.local.kdl.

Behavior:
- If the selected display is not present in outputs.local.kdl, append a new output block.
- If the selected display already exists, show a diff and ask before replacing it.
EOF
}

main() {
    local username
    local output_file=""
    local assume_yes="false"

    username=$(whoami)

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                if [[ $# -lt 2 ]]; then
                    usage >&2
                    return 1
                fi
                username=$2
                shift 2
                ;;
            --output-file)
                if [[ $# -lt 2 ]]; then
                    usage >&2
                    return 1
                fi
                output_file=$2
                shift 2
                ;;
            --yes)
                assume_yes="true"
                shift
                ;;
            -h|--help)
                usage
                return 0
                ;;
            *)
                echo "Unknown argument: $1" >&2
                usage >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$output_file" ]]; then
        output_file="/home/${username}/.config/niri/outputs.local.kdl"
    fi

    md4n_display_configure_outputs "$username" "$output_file" "$assume_yes"
}

main "$@"
