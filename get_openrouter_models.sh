#!/usr/bin/env bash
# OpenRouter models fetcher
set -euo pipefail
IFS=$'\n\t'

# Check dependencies
for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found" >&2
        exit 1
    fi
done

# Build curl command (API key is optional for OpenRouter)
curl_args=(
    -sS
    --fail-with-body
    --max-time 30
    https://openrouter.ai/api/v1/models
)

if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${OPENROUTER_API_KEY}")
fi

# Fetch models with error handling
response=$(curl "${curl_args[@]}" 2>&1) || {
    echo "Error: curl failed" >&2
    echo "$response" >&2
    exit 1
}

# Check for API errors
if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: API returned error:" >&2
    echo "$response" | jq '.error' >&2
    exit 1
fi

# Validate JSON structure
if ! echo "$response" | jq -e '.data' >/dev/null 2>&1; then
    echo "Error: unexpected JSON structure" >&2
    exit 1
fi

# Output formatted model list
echo "        default: ["
echo "$response" | jq -r '.data | sort_by(.id) | .[-1].id as $last | .[].id | "            \"\(.)\"" + (if . == $last then "" else "," end)'
echo "            ]"
