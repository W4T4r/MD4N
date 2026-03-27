#!/usr/bin/env bash

MD4N_DISPLAY_BLUE='\033[0;34m'
MD4N_DISPLAY_GREEN='\033[0;32m'
MD4N_DISPLAY_YELLOW='\033[1;33m'
MD4N_DISPLAY_RED='\033[0;31m'
MD4N_DISPLAY_CYAN='\033[0;36m'
MD4N_DISPLAY_DIM='\033[2m'
MD4N_DISPLAY_NC='\033[0m'

md4n_display_info() { echo -e "${MD4N_DISPLAY_BLUE}[INFO]${MD4N_DISPLAY_NC} $1"; }
md4n_display_success() { echo -e "${MD4N_DISPLAY_GREEN}[SUCCESS]${MD4N_DISPLAY_NC} $1"; }
md4n_display_warn() { echo -e "${MD4N_DISPLAY_YELLOW}[WARN]${MD4N_DISPLAY_NC} $1"; }
md4n_display_error() { echo -e "${MD4N_DISPLAY_RED}[ERROR]${MD4N_DISPLAY_NC} $1" >&2; return 1; }
md4n_display_step() { echo -e "\n${MD4N_DISPLAY_CYAN}==>${MD4N_DISPLAY_NC} $1"; }
md4n_display_detail() { echo -e "   ${MD4N_DISPLAY_DIM}$1${MD4N_DISPLAY_NC}"; }

md4n_display_is_interactive() {
    [[ -t 0 ]]
}

md4n_display_has_nix() {
    command -v nix >/dev/null 2>&1
}

md4n_display_run_nixpkgs_command() {
    local package=$1
    shift

    if ! md4n_display_has_nix; then
        return 1
    fi

    nix shell "nixpkgs#${package}" --command "$@" 2>/dev/null
}

md4n_display_get_modetest_output() {
    if [[ -n "${MD4N_DISPLAY_MODETEST_OUTPUT:-}" ]]; then
        printf '%s\n' "${MD4N_DISPLAY_MODETEST_OUTPUT}"
        return 0
    fi

    if command -v modetest >/dev/null 2>&1; then
        modetest -c 2>/dev/null || true
        return 0
    fi

    if md4n_display_has_nix; then
        md4n_display_warn "modetest is not available in PATH. Falling back to a temporary nix shell with libdrm." >&2
        md4n_display_run_nixpkgs_command libdrm modetest -c || true
    fi
}

md4n_display_collect_connected_drm_outputs() {
    local modetest_output=""

    modetest_output=$(md4n_display_get_modetest_output)
    if [[ -z "$modetest_output" ]]; then
        return 0
    fi

    printf '%s\n' "$modetest_output" | awk '
        function flush_connector() {
            if (connector_name == "" || connector_status != "connected") {
                return
            }

            print connector_name "|" mm_width "|" mm_height "|" preferred_mode "|" modes
        }

        /^[0-9]+\t[0-9]+\t(connected|disconnected)\t/ {
            flush_connector()

            connector_status = $3
            connector_name = $4
            split($5, size_parts, "x")
            mm_width = size_parts[1]
            mm_height = size_parts[2]
            preferred_mode = ""
            modes = ""
            in_modes = 0
            next
        }

        $1 == "modes:" {
            in_modes = 1
            next
        }

        in_modes && $1 == "index" {
            next
        }

        in_modes && /^[[:space:]]*#/ {
            refresh = $3
            gsub(/[^0-9.]/, "", refresh)
            mode = sprintf("%s@%.3f", $2, refresh + 0)

            if (modes != "") {
                modes = modes "," mode
            } else {
                modes = mode
            }

            if ($0 ~ /preferred/) {
                preferred_mode = mode
            }
            next
        }

        in_modes && /^[[:space:]]*props:/ {
            in_modes = 0
            next
        }

        END {
            flush_connector()
        }
    '
}

md4n_display_suggest_output_scale() {
    local mode=$1
    local mm_width=${2:-0}
    local mm_height=${3:-0}
    local width=${mode%%x*}
    local rest=${mode#*x}
    local height=${rest%@*}

    if [[ "$mm_width" =~ ^[0-9]+$ && "$mm_height" =~ ^[0-9]+$ && "$mm_width" -gt 0 && "$mm_height" -gt 0 ]]; then
        awk -v w="$width" -v h="$height" -v mmw="$mm_width" -v mmh="$mm_height" '
            function sqrt_approx(x) { return sqrt(x) }
            BEGIN {
                pixel_diag = sqrt_approx((w * w) + (h * h))
                inch_diag = sqrt_approx((mmw * mmw) + (mmh * mmh)) / 25.4
                dpi = (inch_diag > 0) ? pixel_diag / inch_diag : 0

                if (dpi >= 210) {
                    print "2.00"
                } else if (dpi >= 160) {
                    print "1.50"
                } else {
                    print "1.00"
                }
            }
        '
        return 0
    fi

    if [[ "$width" -ge 3000 ]]; then
        printf '2.00\n'
    elif [[ "$width" -ge 2200 ]]; then
        printf '1.50\n'
    else
        printf '1.00\n'
    fi
}

md4n_display_validate_scale_value() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

md4n_display_select_output_index() {
    local default_index=$1
    local total=$2
    local answer=""

    while true; do
        read -r -p "Select the output to configure [${default_index}]: " answer
        answer=${answer:-$default_index}

        if [[ "$answer" =~ ^[0-9]+$ && "$answer" -ge 1 && "$answer" -le "$total" ]]; then
            printf '%s\n' "$answer"
            return 0
        fi

        md4n_display_warn "Please enter a number between 1 and ${total}."
    done
}

md4n_display_select_mode_index() {
    local default_index=$1
    local total=$2
    local answer=""

    while true; do
        read -r -p "Select the output mode [${default_index}]: " answer
        answer=${answer:-$default_index}

        if [[ "$answer" =~ ^[0-9]+$ && "$answer" -ge 1 && "$answer" -le "$total" ]]; then
            printf '%s\n' "$answer"
            return 0
        fi

        md4n_display_warn "Please enter a number between 1 and ${total}."
    done
}

md4n_display_escape_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '%s' "$value"
}

md4n_display_render_niri_outputs_config() {
    local output_name=$1
    local output_mode=$2
    local output_scale=$3

    cat <<EOF
// Output configuration.
// Auto-generated by scripts/configure-niri-outputs.sh
// Find more information on the wiki:
// https://yalter.github.io/niri/Configuration:-Outputs

output "$(md4n_display_escape_string "$output_name")" {
    mode "$(md4n_display_escape_string "$output_mode")"
    scale ${output_scale}
    transform "normal"
    focus-at-startup
    background-color "#2e2e30"
    backdrop-color "#2e2e30"

    hot-corners {
        top-left
    }
}
EOF
}

md4n_display_output_exists() {
    local output_file=$1
    local output_name=$2

    [[ -f "$output_file" ]] || return 1

    awk -v target="$output_name" '
        function extract_name(line, tmp, name) {
            tmp = line
            if (tmp !~ /^[[:space:]]*output[[:space:]]+"/) {
                return ""
            }

            sub(/^[[:space:]]*output[[:space:]]+"/, "", tmp)
            name = tmp
            sub(/".*$/, "", name)
            return name
        }

        extract_name($0) == target && $0 ~ /\{[[:space:]]*$/ {
            found = 1
            exit 0
        }

        END {
            exit(found ? 0 : 1)
        }
    ' "$output_file"
}

md4n_display_merge_append() {
    local existing_file=$1
    local block_file=$2
    local merged_file=$3

    awk -v block_file="$block_file" '
        {
            lines[NR] = $0
        }

        END {
            last = NR
            while (last > 0 && lines[last] == "") {
                last--
            }

            for (i = 1; i <= last; i++) {
                print lines[i]
            }

            if (last > 0) {
                print ""
                print ""
            }

            while ((getline line < block_file) > 0) {
                print line
            }
            close(block_file)
        }
    ' "$existing_file" > "$merged_file"
}

md4n_display_merge_replace() {
    local existing_file=$1
    local output_name=$2
    local block_file=$3
    local merged_file=$4

    awk -v target="$output_name" '
        function brace_delta(line, tmp, opens, closes) {
            tmp = line
            opens = gsub(/\{/, "{", tmp)
            closes = gsub(/\}/, "}", tmp)
            return opens - closes
        }

        function extract_name(line, tmp, name) {
            tmp = line
            if (tmp !~ /^[[:space:]]*output[[:space:]]+"/) {
                return ""
            }

            sub(/^[[:space:]]*output[[:space:]]+"/, "", tmp)
            name = tmp
            sub(/".*$/, "", name)
            return name
        }

        FNR == NR {
            replacement = replacement $0 ORS
            next
        }

        !skipping {
            if (extract_name($0) == target && $0 ~ /\{[[:space:]]*$/) {
                if (!replaced) {
                    printf "%s", replacement
                    replaced = 1
                }
                skipping = 1
                depth = brace_delta($0)
                if (depth <= 0) {
                    skipping = 0
                }
                next
            }

            print
            next
        }

        {
            depth += brace_delta($0)
            if (depth <= 0) {
                skipping = 0
            }
        }
    ' "$block_file" "$existing_file" > "$merged_file"
}

md4n_display_apply_output_config() {
    local username=$1
    shift
    local output_file=$1
    local connector_name=$2
    local selected_mode=$3
    local selected_scale=$4
    local assume_yes=${5:-false}
    local output_backup=""
    local temp_dir=""
    local block_file=""
    local merged_file=""
    local action="create"
    local prompt_answer=""

    output_backup="/home/${username}/.local/state/md4n/niri/$(basename "$output_file").bak"

    mkdir -p "$(dirname "$output_file")"
    mkdir -p "$(dirname "$output_backup")"

    temp_dir=$(mktemp -d)
    block_file="${temp_dir}/output-block.kdl"
    merged_file="${temp_dir}/$(basename "$output_file")"

    md4n_display_render_niri_outputs_config "$connector_name" "$selected_mode" "$selected_scale" > "$block_file"

    if [[ -f "$output_file" ]]; then
        if md4n_display_output_exists "$output_file" "$connector_name"; then
            action="replace"
            md4n_display_merge_replace "$output_file" "$connector_name" "$block_file" "$merged_file"
        else
            action="append"
            md4n_display_merge_append "$output_file" "$block_file" "$merged_file"
        fi
    else
        cp "$block_file" "$merged_file"
    fi

    if [[ -f "$output_file" ]] && cmp -s "$output_file" "$merged_file"; then
        rm -rf "$temp_dir"
        md4n_display_success "No changes needed for ${output_file}"
        return 0
    fi

    if [[ "$action" == "replace" ]]; then
        md4n_display_info "Existing output \"${connector_name}\" found. Review the diff before applying."
        echo
        diff -u "$output_file" "$merged_file" || true
        echo

        if [[ "$assume_yes" != "true" ]]; then
            if md4n_display_is_interactive; then
                read -r -p "Apply this $(basename "$output_file") update? [y/N] " prompt_answer
                if [[ ! "$prompt_answer" =~ ^[yY]$ ]]; then
                    rm -rf "$temp_dir"
                    md4n_display_info "Keeping existing ${output_file}"
                    return 0
                fi
            else
                rm -rf "$temp_dir"
                md4n_display_warn "Non-interactive mode detected. Keeping the existing ${output_file} because confirmation is required."
                return 0
            fi
        fi
    elif [[ "$action" == "append" ]]; then
        md4n_display_info "Adding a new output entry for ${connector_name} to ${output_file}."
    else
        md4n_display_info "Generating ${output_file}..."
    fi

    if [[ -f "$output_file" ]]; then
        md4n_display_warn "Creating backup of $(basename "$output_file")..."
        cp "$output_file" "$output_backup"
        md4n_display_detail "Backup path: ${output_backup}"
    fi

    mv "$merged_file" "$output_file"
    rm -rf "$temp_dir"

    case "$action" in
        append)
            md4n_display_success "Appended ${connector_name} to ${output_file}"
            ;;
        replace)
            md4n_display_success "Updated ${output_file}"
            ;;
        *)
            md4n_display_success "Created ${output_file}"
            ;;
    esac
}

md4n_display_configure_outputs() {
    local username=$1
    local output_file=${2:-"/home/${username}/.config/niri/outputs.kdl"}
    local assume_yes=${3:-false}
    local -a outputs=()
    local -a mode_list=()
    local i=0
    local connector_name=""
    local mm_width=""
    local mm_height=""
    local preferred_mode=""
    local modes_csv=""
    local selected_output_index=1
    local selected_mode_index=1
    local selected_output=""
    local selected_mode=""
    local selected_scale=""
    local default_output_index=1
    local default_mode_index=1
    local prompt_value=""
    local output_summary=""

    mapfile -t outputs < <(md4n_display_collect_connected_drm_outputs)

    if [[ ${#outputs[@]} -eq 0 ]]; then
        md4n_display_warn "No connected DRM outputs were detected. Keeping the existing niri outputs configuration."
        return 0
    fi

    md4n_display_step "Preparing niri output configuration"
    md4n_display_detail "Using modetest to detect DRM connectors, modes, and preferred timings."

    if md4n_display_is_interactive; then
        md4n_display_detail "Detected outputs:"
        for i in "${!outputs[@]}"; do
            IFS='|' read -r connector_name mm_width mm_height preferred_mode modes_csv <<< "${outputs[$i]}"
            output_summary=$connector_name
            if [[ -n "$preferred_mode" ]]; then
                output_summary="${output_summary} (preferred ${preferred_mode})"
            fi
            if [[ "$mm_width" != "0" && "$mm_height" != "0" ]]; then
                output_summary="${output_summary}, ${mm_width}x${mm_height}mm"
            fi
            md4n_display_detail "  $((i + 1)). ${output_summary}"

            if [[ "$connector_name" == eDP-* ]]; then
                default_output_index=$((i + 1))
            fi
        done

        selected_output_index=$(md4n_display_select_output_index "$default_output_index" "${#outputs[@]}")
    fi

    selected_output="${outputs[$((selected_output_index - 1))]}"
    IFS='|' read -r connector_name mm_width mm_height preferred_mode modes_csv <<< "$selected_output"
    IFS=',' read -r -a mode_list <<< "$modes_csv"

    if [[ ${#mode_list[@]} -eq 0 ]]; then
        md4n_display_warn "No display modes were detected for ${connector_name}. Keeping the existing niri outputs configuration."
        return 0
    fi

    if [[ -n "$preferred_mode" ]]; then
        for i in "${!mode_list[@]}"; do
            if [[ "${mode_list[$i]}" == "$preferred_mode" ]]; then
                default_mode_index=$((i + 1))
                break
            fi
        done
    fi

    if md4n_display_is_interactive; then
        md4n_display_detail "Available modes for ${connector_name}:"
        for i in "${!mode_list[@]}"; do
            output_summary="${mode_list[$i]}"
            if [[ $((i + 1)) -eq "$default_mode_index" ]]; then
                output_summary="${output_summary} [preferred]"
            fi
            md4n_display_detail "  $((i + 1)). ${output_summary}"
        done

        selected_mode_index=$(md4n_display_select_mode_index "$default_mode_index" "${#mode_list[@]}")
    else
        selected_mode_index=$default_mode_index
    fi

    selected_mode="${mode_list[$((selected_mode_index - 1))]}"
    selected_scale=$(md4n_display_suggest_output_scale "$selected_mode" "$mm_width" "$mm_height")

    if md4n_display_is_interactive; then
        md4n_display_detail "Suggested scale for ${connector_name} at ${selected_mode}: ${selected_scale}"
        read -r -p "Enter scale for ${connector_name} [${selected_scale}]: " prompt_value
        prompt_value=${prompt_value:-$selected_scale}

        if ! md4n_display_validate_scale_value "$prompt_value"; then
            md4n_display_error "Invalid scale value: ${prompt_value}"
            return 1
        fi

        selected_scale=$(printf '%.2f' "$prompt_value")
    fi

    md4n_display_apply_output_config "$username" "$output_file" "$connector_name" "$selected_mode" "$selected_scale" "$assume_yes"
    md4n_display_detail "Output   : ${connector_name}"
    md4n_display_detail "Mode     : ${selected_mode}"
    md4n_display_detail "Scale    : ${selected_scale}"
}
