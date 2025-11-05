#!/usr/bin/env bash
# cat * $PWD + optional headers between files:
# excludes hidden files and directories (*.), 'uv.lock'
# and files listed in .gitignore or .*ignore
# Use -H or --headers to show file headers and footers

show_headers=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    -H | --headers)
        show_headers=true
        shift
        ;;
    *)
        shift
        ;;
    esac
done

# --- Configuration ---
# Files/directories starting with '.' are excluded by default
excluded_files='uv.lock' # Specific files to exclude by name

# --- Helper Functions ---

# Function to check if a file is likely a text file
is_text_file() {
    local file="$1"
    # Use file command to check encoding. 'binary' indicates non-text.
    # Consider other non-text types if needed.
    [[ "$(file -b --mime-encoding "$file")" != "binary" ]]
}

# Function to check if a file path matches any ignore pattern
# Note: This is a basic implementation and might not handle all .gitignore syntax correctly.
is_ignored() {
    local file="$1"
    local patterns="$2"
    # Remove leading ./ for matching patterns
    local relfile="${file#./}"
    echo "$relfile" | grep -E -q "$patterns"
}

# Function to process and print a file
process_file() {
    local file="$1"
    # Remove leading ./ for display
    local relfile="${file#./}"

    if $show_headers; then
        echo "# File: $relfile"
        echo "#######"
        echo
    fi

    cat "$file"

    if $show_headers; then
        echo
        echo "# EOF: $relfile"
        echo
    fi
}

# --- Main Logic ---

# Build ignore patterns from .gitignore and .*ignore files
# Replace newlines with '|' for grep -E, remove trailing '|'
ignore_patterns=$(find . -maxdepth 1 -type f \( -name ".gitignore" -o -name ".*ignore" \) -print0 2>/dev/null | xargs -0 cat 2>/dev/null | grep -v '^#' | grep -v '^[[:space:]]*$' | tr '\n' '|' | sed 's/|$//')

# Find files, excluding hidden ones and specific names
find . -type f \
    ! -name '.*' \
    ! -path './.*' \
    ! -name "$excluded_files" \
    -print0 |
    while IFS= read -r -d '' file; do
        # Check if ignored by patterns
        if [[ -n "$ignore_patterns" ]] && is_ignored "$file" "$ignore_patterns"; then
            continue # Skip ignored files
        fi

        # Check if it's a text file
        if ! is_text_file "$file"; then
            continue # Skip non-text files
        fi

        # If not ignored and is text, process it
        process_file "$file"

    done || true # Add || true to prevent exit code 1 if find yields no results
