# Azure Cost Analysis: Landing Page

Actual cost of the Azure-hosted landing page (`<custom-domain>`), pulled from the Azure Cost Management API on 2026-10-26.

- **Subscription:** `<subscription-name>`
- **Resource groups:** `<site-resource-group>` (site + Front Door), `<dns-resource-group>` (DNS zone)
- **Cost type:** Actual cost, USD
- **Period:** 2026-09-22 (first charge) to 2026-10-26. Cost data lags by up to 24 hours, so 2026-10-26 is partial.

## Summary

| Period | Front Door | DNS | Storage + bandwidth | Total |
|---|---:|---:|---:|---:|
| Sep 2026 (Sep 22–30) | $9.04 | $0.13 | $0.02 | **$9.19** |
| Oct 2026 (Oct 1–26, partial) | $29.09 | $0.42 | $0.08 | **$29.58** |
| **To date** | **$38.13** | **$0.55** | **$0.10** | **$38.78** |

**Steady-state run rate:** about $1.149/day, which is **about $35.60 for a 31-day month** and **about $419/year**.

## Comparison window: Oct 1–25, 2026

A fixed 25-day window of complete days, so the AWS stack can be measured over the same days in November (Nov 1–25, 2026) and compared like for like. Pulled 2026-10-27; all 25 days are final.

| Category | Oct 1–25 | Share |
|---|---:|---:|
| Front Door (base fee $28.23, requests + data transfer $0.015) | $28.24 | 98.3% |
| DNS (zone $0.40, queries $0.004) | $0.41 | 1.4% |
| Storage + bandwidth | $0.07 | 0.3% |
| **Total** | **$28.72** | |

- **Daily average:** $1.149 (range $1.148–$1.152). The flat base fee keeps every day nearly identical.
- **Traffic:** about 9.5K Front Door requests and 0.06 GB out over the window.
- **Storage operations:** about 183K, almost all Front Door health probes.

Files: `2026-10-01_2026-10-25-by-meter.csv` (cost and usage per meter) and `2026-10-01_2026-10-25-daily.csv` (cost per day and service).

## Where the money goes

| Resource | Meter | Cost/day | Cost/month (31d) | Share |
|---|---|---:|---:|---:|
| `<front-door-profile>` | Front Door Standard **Base Fee** | $1.129 | $35.00 | 98.2% |
| `<dns-zone>` | DNS Public Zone | $0.016 | $0.50 | 1.4% |
| `<storage-account>` | Storage operations (mostly "All Other Operations") | $0.003 | $0.09 | 0.3% |
| `<front-door-profile>` | Front Door requests + data transfer | $0.0006 | $0.02 | <0.1% |
| `<dns-zone>` | DNS queries | $0.0001 | $0.005 | <0.1% |

Findings:

- **The Front Door Standard base fee is almost the entire bill.** It's a flat $35/month, prorated daily, charged whether or not the site gets traffic.
- **Actual traffic costs are negligible.** In October to date, Front Door served about 9.7K requests and about 0.06 GB, costing $0.015 combined.
- **Most storage spend is Front Door health probes.** "All Other Operations" (~188K operations in October) matches the origin group's `HEAD /` probe running every 120 seconds from each Front Door edge location. That's still only about $0.08/month.
- Storage capacity (under 1 GB) costs fractions of a cent.

Without the Front Door base fee, the Azure footprint would cost about **$0.60/month**.

## AWS comparison (estimate)

The planned AWS stack in `infrastructure/aws/` (S3 + CloudFront + ACM + Route 53) has no fixed CDN fee. At current traffic it's expected to cost about **$0.51/month**: $0.50 for the Route 53 hosted zone, with S3, CloudFront, and ACM within free tiers or under $0.01. That saves about **$35/month, or about $420/year**. Confirm with actual AWS cost for Nov 1–25, 2026, against the $28.72 Azure baseline above.

## Files

- `2026-10-01_2026-10-25-by-meter.csv` and `2026-10-01_2026-10-25-daily.csv`: the Oct 1–25 comparison window
- `monthly-by-meter.csv`: monthly cost and usage per resource group, service, meter, and resource
- `daily-by-service.csv`: daily cost per service
- `pull-costs.sh`: re-runs the queries (requires `az login` on the subscription; set `SUBSCRIPTION_ID`, `SITE_RESOURCE_GROUP`, and `DNS_RESOURCE_GROUP`)
