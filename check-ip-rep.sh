#!/bin/bash

# --- Configuration ---
# A list of significant DNSBLs. zen.spamhaus.org is a composite of SBL, XBL, PBL.
DNSBL_LIST=(
    "zen.spamhaus.org"
    "bl.spamcop.net"
    "b.barracudacentral.org"
    "dnsbl-1.uceprotect.net"
    "all.s5h.net"
)

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Functions ---
usage() {
    echo "Usage: $0 <IP_ADDRESS>"
    echo "Checks an IP address against major email blacklists (DNSBLs)."
    echo "Optionally checks AbuseIPDB if ABUSEIPDB_KEY environment variable is set."
    exit 1
}

reverse_ip() {
    echo "$1" | awk -F. '{print $4"."$3"."$2"."$1}'
}

# --- Main Logic ---

# Check for dependencies
for cmd in dig curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Error: Command '$cmd' not found. Please install it.${NC}"
        exit 1
    fi
done

# Check for input IP address
IP_ADDRESS="$1"
if [[ -z "$IP_ADDRESS" ]] || ! [[ "$IP_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    usage
fi

REVERSED_IP=$(reverse_ip "$IP_ADDRESS")
LISTED_COUNT=0

echo -e "--- Checking DNSBLs for ${CYAN}${IP_ADDRESS}${NC} ---"

for dnsbl in "${DNSBL_LIST[@]}"; do
    printf "%-30s" "Checking $dnsbl..."
    # The '+short' option makes 'dig' output only the result.
    result=$(dig +short A "$REVERSED_IP.$dnsbl.")

    if [[ -n "$result" ]]; then
        printf "${RED}LISTED${NC} (Result: %s)\n" "$result"
        ((LISTED_COUNT++))
    else
        printf "${GREEN}OK${NC}\n"
    fi
done

echo "" # Newline for separation

# Optional: AbuseIPDB Check
if [[ -n "$ABUSEIPDB_KEY" ]]; then
    echo -e "--- Checking AbuseIPDB for ${CYAN}${IP_ADDRESS}${NC} ---"
    printf "%-30s" "Querying API..."

    response=$(curl -s --request GET \
        --url "https://api.abuseipdb.com/api/v2/check?ipAddress=${IP_ADDRESS}&maxAgeInDays=90" \
        --header "Key: ${ABUSEIPDB_KEY}" \
        --header "Accept: application/json")

    # Check if the response contains an error
    if echo "$response" | jq -e '.errors' >/dev/null; then
        error_detail=$(echo "$response" | jq -r '.errors[0].detail')
        printf "${RED}API ERROR${NC} (Detail: %s)\n" "$error_detail"
    else
        score=$(echo "$response" | jq -r '.data.abuseConfidenceScore')
        reports=$(echo "$response" | jq -r '.data.totalReports')

        if [[ "$score" -gt 0 ]]; then
            printf "${YELLOW}SCORE: %s/100${NC} (Total reports: %s)\n" "$score" "$reports"
        else
            printf "${GREEN}CLEAN${NC} (Score: 0/100)\n"
        fi
    fi
else
    echo -e "--- ${YELLOW}Skipping AbuseIPDB check.${NC} ---"
    echo "Set the 'ABUSEIPDB_KEY' environment variable to enable this check."
fi
echo ""

echo "--- Summary ---"
if [[ $LISTED_COUNT -gt 0 ]]; then
    echo -e "Result: ${IP_ADDRESS} was found on ${RED}${LISTED_COUNT}${NC} of ${#DNSBL_LIST[@]} blacklists."
else
    echo -e "Result: ${IP_ADDRESS} was ${GREEN}not found${NC} on any of the checked blacklists."
fi
