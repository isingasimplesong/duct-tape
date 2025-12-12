#!/usr/bin/env bash
# OpenAI models fetcher
set -euo pipefail
IFS=$'\n\t'

# Validate API key
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "Error: OPENAI_API_KEY not set" >&2
    exit 1
fi

# Check dependencies
for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found" >&2
        exit 1
    fi
done

# Fetch models with error handling
response=$(curl -sS --fail-with-body --max-time 30 \
    https://api.openai.com/v1/models \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" 2>&1) || {
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
