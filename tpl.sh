#!/usr/bin/env bash

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Determine the directory where this script resides.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Directory where the .tpl files are stored.
# 1. Use TPL_TEMPLATE_DIR environment variable if set and not empty.
# 2. Default to the directory containing this script.
TEMPLATE_DIR="${TPL_TEMPLATE_DIR:-$SCRIPT_DIR}"

usage() {
    cat <<EOF
Usage: $(basename "$0") <template_type> <destination_path>

Generates a new script or file from a predefined template and opens it
in \$EDITOR if set.

Arguments:
  template_type     The type of template to use (e.g., 'bash', 'python', 'golang'...).
                    Looks for a file named '<template_type>.tpl' in the template directory.
  destination_path  The full path where the new file should be created.

Options:
  -h, --help        Display this help message and exit.

Template Directory:
  Templates are currently sourced from: $TEMPLATE_DIR
  (This can be configured by setting the TPL_TEMPLATE_DIR environment variable)

Available Templates:
EOF
    # List available .tpl files from the configured directory
    if [[ -d "$TEMPLATE_DIR" ]]; then
        # Use find if available and directory exists, otherwise indicate no templates/dir
        find "$TEMPLATE_DIR" -maxdepth 1 -name '*.tpl' -printf '  - %f\n' 2>/dev/null | sed 's/\.tpl$//' || echo "  (No templates found or error listing templates in $TEMPLATE_DIR)"
    else
        echo "  (Template directory '$TEMPLATE_DIR' not found)"
    fi
    exit 0
}

log_error() {
    echo "[ERROR] $@" >&2
}

log_info() {
    echo "[INFO] $@"
}

# --- Argument Parsing ---
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage # Exits
fi

if [[ "$#" -ne 2 ]]; then
    log_error "Invalid number of arguments. Expected 2, got $#."
    echo "---"
    usage # Exits
fi

template_type="$1"
dest_path="$2"
template_filename="${template_type}.tpl"
template_file="${TEMPLATE_DIR}/${template_filename}"

# Check if the determined template directory exists
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    log_error "Template directory not found: $TEMPLATE_DIR"
    log_error "Please create it or set the TPL_TEMPLATE_DIR environment variable correctly."
    exit 1
fi

# Check if template file exists within the template directory
if [[ ! -f "$template_file" ]]; then
    log_error "Template file not found: $template_file"
    log_error "Ensure a file named '$template_filename' exists in '$TEMPLATE_DIR'"
    echo "---"
    usage
fi

# Check if destination file already exists
if [[ -e "$dest_path" ]]; then
    log_error "Destination path already exists: $dest_path"
    exit 1
fi

# Check if destination directory exists, create if not
dest_dir=$(dirname "$dest_path")
# Handle edge case where dirname is '.' (current directory)
if [[ "$dest_dir" != "." && ! -d "$dest_dir" ]]; then
    log_info "Creating directory: $dest_dir"
    mkdir -p "$dest_dir"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to create directory: $dest_dir"
        exit 1
    fi
fi

# --- Generation ---
log_info "Generating '$dest_path' from template '$template_file'..."
cp "$template_file" "$dest_path"
if [[ $? -ne 0 ]]; then
    log_error "Failed to copy template to destination."
    exit 1
fi

# --- Set Executable Permissions (Optional) ---
# Make bash and python scripts executable by default
if [[ "$template_type" == "bash" || "$template_type" == "python" ]]; then
    log_info "Making '$dest_path' executable..."
    chmod +x "$dest_path"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to set executable permissions on '$dest_path'."
        # Don't exit, file was created, permissions are secondary
    fi
fi

log_info "File created successfully: $dest_path"

# Check if EDITOR variable is set and not empty
if [[ -n "${EDITOR:-}" ]]; then
    log_info "Opening '$dest_path' with \$EDITOR ('$EDITOR')..."
    "$EDITOR" "$dest_path"
else
    log_info "Skipping auto-open: \$EDITOR environment variable is not set."
fi

exit 0
