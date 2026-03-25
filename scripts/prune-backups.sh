#!/usr/bin/env bash

set -euo pipefail

NC=$'\033[0m'
BOLD=$'\033[1m'
BLUE=$'\033[0;34m'
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GRAY=$'\033[0;90m'

files=()
total_size=0
file_count=0

should_quit() {
    [[ "${1:-}" =~ ^[qQ]$ ]]
}

human_size() {
    local size=$1

    if (( size < 1024 )); then
        printf '%s B' "$size"
    elif (( size < 1048576 )); then
        printf '%s K' "$(( size / 1024 ))"
    else
        printf '%s M' "$(( size / 1048576 ))"
    fi
}

echo
echo "${BLUE}==> Scanning for MD4N backups...${NC}"

while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find "$HOME" -name "*.md4nbak" -print0 2>/dev/null)

file_count=${#files[@]}
if (( file_count == 0 )); then
    echo "${GREEN}No action needed.${NC}"
    echo
    exit 0
fi

echo
printf "${GRAY}%-10s %-12s %s${NC}\n" "SIZE" "MODIFIED" "PATH"
echo "${GRAY}------------------------------------------------------------${NC}"

for file in "${files[@]}"; do
    size=$(stat -c '%s' "$file" 2>/dev/null || printf '0')
    mtime=$(stat -c '%y' "$file" 2>/dev/null | cut -d' ' -f1)
    display_path=${file/#$HOME/\~}
    type_icon="FILE"

    if [[ -d "$file" ]]; then
        type_icon="DIR "
    fi

    total_size=$(( total_size + size ))
    printf "%-10s %-12s %s ${YELLOW}%s${NC}\n" \
        "$(human_size "$size")" \
        "$mtime" \
        "$type_icon" \
        "$display_path"
done

echo "${GRAY}------------------------------------------------------------${NC}"
echo "Found ${BOLD}${file_count}${NC} backup files that can be removed. Total reclaimable space: ${RED}$(human_size "$total_size")${NC}"
echo

prompt="$(printf '%b' "${BLUE}[?]${NC} Remove MD4N backups now? [y/N] ")"
read -r -p "$prompt" confirm
if should_quit "$confirm"; then
    echo
    exit 0
fi

if [[ "$confirm" =~ ^[yY]$ ]]; then
    rm -rf -- "${files[@]}"
    echo "${GREEN}Updated successfully.${NC}"
else
    echo "${YELLOW}Skipped.${NC}"
fi

echo
