#!/usr/bin/env sh

START=2025-10-06
LAST_BUY=2026-01-06
THIS_MONTH=2026-01-01
TO_DATE=$(date +%Y-%m-%d)

st graph perf --tickers @indices --benchmark "@reer:red, @celi:green" --from-date "$THIS_MONTH"
# st graph perf --tickers @indices --benchmark "@reer:purple, @celi:green" --from-date "$LAST_BUY"
st graph perf --tickers @indices --benchmark "@reer:red, @celi:green" --from-date "$START"
st portfolio evolution --from-date "$START"
st portfolio evolution --from-date "$LAST_BUY"
