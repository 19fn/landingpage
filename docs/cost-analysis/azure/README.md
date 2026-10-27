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

The planned AWS stack in `infrastructure/aws/` (S3 + CloudFront + ACM + Route 53) has no fixed CDN fee. At current traffic it's expected to cost about **$0.51/month**: $0.50 for the Route 53 hosted zone, with S3, CloudFront, and ACM within free tiers or under $0.01. That saves about **$35/month, or about $420/year**.

## Files

- `monthly-by-meter.csv`: monthly cost and usage per resource group, service, meter, and resource
- `daily-by-service.csv`: daily cost per service
- `pull-costs.sh`: re-runs the queries (requires `az login` on the subscription; set `SUBSCRIPTION_ID`, `SITE_RESOURCE_GROUP`, and `DNS_RESOURCE_GROUP`)
