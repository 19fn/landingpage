#!/usr/bin/env bash
# Pulls actual landing-page costs from Azure Cost Management.
# Usage: SITE_RESOURCE_GROUP=<rg> DNS_RESOURCE_GROUP=<rg> ./pull-costs.sh [from-date] [to-date]
#        (dates default to 2026-09-01 .. today; SUBSCRIPTION_ID defaults to the active az account)
set -euo pipefail

: "${SITE_RESOURCE_GROUP:?Set SITE_RESOURCE_GROUP}"
: "${DNS_RESOURCE_GROUP:?Set DNS_RESOURCE_GROUP}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
FROM="${1:-2026-09-01}"
TO="${2:-$(date -u +%Y-%m-%d)}"
OUT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILTER='"filter":{"dimensions":{"name":"ResourceGroupName","operator":"In","values":["'"$SITE_RESOURCE_GROUP"'","'"$DNS_RESOURCE_GROUP"'"]}}'
URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.CostManagement/query?api-version=2023-11-01"

# The Cost Management API rate-limits aggressively (HTTP 429), so retry.
query() {
  for _ in 1 2 3 4 5; do
    if az rest --method post --url "$URL" --body "$1" -o json 2>/tmp/cost-query.err; then
      return 0
    fi
    grep -q 429 /tmp/cost-query.err || { cat /tmp/cost-query.err >&2; return 1; }
    sleep 60
  done
  return 1
}

query '{"type":"ActualCost","timeframe":"Custom","timePeriod":{"from":"'"$FROM"'T00:00:00Z","to":"'"$TO"'T23:59:59Z"},"dataset":{"granularity":"Monthly","aggregation":{"totalCost":{"name":"Cost","function":"Sum"},"qty":{"name":"UsageQuantity","function":"Sum"}},"grouping":[{"type":"Dimension","name":"ResourceGroupName"},{"type":"Dimension","name":"ServiceName"},{"type":"Dimension","name":"Meter"},{"type":"Dimension","name":"ResourceId"}],'"$FILTER"'}}' >/tmp/cost-monthly.json
sleep 20
query '{"type":"ActualCost","timeframe":"Custom","timePeriod":{"from":"'"$FROM"'T00:00:00Z","to":"'"$TO"'T23:59:59Z"},"dataset":{"granularity":"Daily","aggregation":{"totalCost":{"name":"Cost","function":"Sum"}},"grouping":[{"type":"Dimension","name":"ServiceName"}],'"$FILTER"'}}' >/tmp/cost-daily.json

python3 - "$OUT_DIR" <<'EOF'
import collections, csv, json, sys

out = sys.argv[1]

rows = json.load(open("/tmp/cost-monthly.json"))["properties"]["rows"]
with open(f"{out}/monthly-by-meter.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["billing_month", "resource_group", "service", "meter", "resource", "usage_quantity", "cost_usd"])
    for cost, qty, month, rg, svc, meter, rid, _ in sorted(rows, key=lambda r: (r[2], -r[0])):
        w.writerow([month[:7], rg, svc, meter, rid.split("/")[-1], f"{qty:.6f}", f"{cost:.6f}"])

rows = json.load(open("/tmp/cost-daily.json"))["properties"]["rows"]
services = sorted({r[2] for r in rows})
days = collections.defaultdict(dict)
for cost, day, svc, _ in rows:
    days[day][svc] = cost
with open(f"{out}/daily-by-service.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["date"] + services + ["total_usd"])
    for day in sorted(days):
        s = str(day)
        w.writerow([f"{s[:4]}-{s[4:6]}-{s[6:]}"] + [f"{days[day].get(x, 0):.4f}" for x in services] + [f"{sum(days[day].values()):.4f}"])
EOF

echo "Wrote ${OUT_DIR}/monthly-by-meter.csv and ${OUT_DIR}/daily-by-service.csv"
