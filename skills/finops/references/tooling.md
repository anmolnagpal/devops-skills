# AWS Cost Tooling Reference

Cost Explorer, Cost & Usage Report (CUR) + Athena, Compute Optimizer, Trusted Advisor, AWS Budgets, CUDOS dashboards.

## Cost Explorer

Interactive cost analysis. Free in console; $0.01 per API request.

### Recipes

| Goal | Setup |
|---|---|
| Top services this month | Group by `SERVICE`, last 30 days, daily granularity |
| Drill into top service | Filter `SERVICE = EC2-Instance`, group by `USAGE_TYPE` |
| Per-account breakdown (AWS Org) | Group by `LINKED_ACCOUNT` |
| Per-team cost | Group by your cost-allocation tag (e.g., `tag:Owner`) |
| Forecast | Forecast view, 3 months out, apply same filters |
| RI/SP recommendations | Reservations → Recommendations. Look-back: try 7 / 30 / 60 days |
| RI/SP utilization | Reservations → Utilization Report |
| RI/SP coverage | Reservations → Coverage Report |
| Reserved instance vs On-Demand spend | Filter `Purchase Option` |

### Save and Share

Save useful views as **Reports** (named, parameterized). Share via dashboard. Set up email subscriptions for monthly snapshots.

## Cost & Usage Report (CUR) + Athena

Hourly, line-item-level data delivered to S3. Most powerful tool but requires setup.

### Setup (once)

1. **Billing console → Cost & Usage Reports → Create report.**
   - Hourly granularity.
   - Resource IDs included.
   - Format: Parquet. Compression: GZIP. Versioning: overwrite.
   - Integration: Athena (creates a CloudFormation stack with crawler + table).
2. Wait 24 hours for first delivery.
3. Query in Athena.

### Useful Queries

```sql
-- Top resources by cost this month
SELECT
  line_item_resource_id,
  line_item_product_code,
  SUM(line_item_unblended_cost) AS cost
FROM cur_table
WHERE bill_billing_period_start_date = date_trunc('month', current_date)
  AND line_item_resource_id != ''
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 50;

-- Cost per tag value (e.g., per Owner tag)
SELECT
  resource_tags_user_owner AS owner,
  SUM(line_item_unblended_cost) AS cost
FROM cur_table
WHERE bill_billing_period_start_date = date_trunc('month', current_date)
GROUP BY 1
ORDER BY 2 DESC;

-- Cross-AZ data transfer hot resources
SELECT
  line_item_resource_id,
  SUM(line_item_unblended_cost) AS cost,
  SUM(line_item_usage_amount) AS gb
FROM cur_table
WHERE line_item_usage_type LIKE '%-DataTransfer-Regional-Bytes%'
  AND bill_billing_period_start_date = date_trunc('month', current_date)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

-- NAT Gateway processing cost by NAT
SELECT
  line_item_resource_id AS nat_gw,
  SUM(line_item_unblended_cost) AS cost
FROM cur_table
WHERE line_item_usage_type LIKE '%NatGateway-Bytes%'
  AND bill_billing_period_start_date = date_trunc('month', current_date)
GROUP BY 1
ORDER BY 2 DESC;

-- Untagged spend
SELECT
  line_item_product_code,
  SUM(line_item_unblended_cost) AS cost
FROM cur_table
WHERE (resource_tags_user_owner IS NULL OR resource_tags_user_owner = '')
  AND line_item_resource_id != ''
  AND bill_billing_period_start_date = date_trunc('month', current_date)
GROUP BY 1
ORDER BY 2 DESC;

-- RI / SP coverage by service
SELECT
  line_item_product_code,
  pricing_term,
  SUM(line_item_unblended_cost) AS cost
FROM cur_table
WHERE bill_billing_period_start_date = date_trunc('month', current_date)
GROUP BY 1, 2
ORDER BY 1, 2;
```

### CUDOS / Cost Intelligence Dashboards

Pre-built QuickSight dashboards on top of CUR. Open-source from AWS Solutions team.

- **CUDOS Dashboard** — granular cost insights, RI/SP utilization, anomalies, per-account/-team views.
- **Cost Intelligence Dashboard (CID)** — executive-level overview.
- **Trusted Advisor Organizational Dashboard** — TA findings across accounts.
- **KPI Dashboard** — coverage, savings opportunities at a glance.

Install via the CID-CMD CLI tool. Cost: QuickSight subscription only (no extra AWS charge).

## Compute Optimizer

Free ML-based right-sizing. Enable at the account or Organization level.

### What It Covers

- EC2 instances (CPU + network; **memory needs CloudWatch agent** for memory-aware recommendations)
- EC2 Auto Scaling Groups
- EBS volumes (suggest gp3 + IOPS/throughput)
- Lambda functions (memory tuning)
- ECS services on Fargate
- RDS instances (cpu, memory, storage — newer feature)

### Workflow

1. Enable for the org (`aws compute-optimizer update-enrollment-status`).
2. Wait 14 days for full data.
3. Review **"Over-provisioned"** findings first — direct downsizing wins.
4. Pull recommendations via API and feed to a sized-action backlog.
5. Apply changes one workload at a time; watch for performance regressions.

### Enhanced Infrastructure Metrics

Optional paid feature ($0.0003360 per resource-hour). Uses 3 months of metrics for recommendations and adds memory utilization (with CW agent). Worth it for steady-state production fleets where reservation purchases hinge on the recommendations.

## Trusted Advisor

Cost-related checks. Full check set requires Business or Enterprise Support.

### Cost Checks

- Low-utilization EC2 instances
- Idle load balancers
- Underutilized EBS volumes
- Unassociated Elastic IPs
- Idle RDS instances
- Reserved Instance / Savings Plan recommendations
- Underutilized Redshift clusters

Pull programmatically: `aws support describe-trusted-advisor-checks` + `describe-trusted-advisor-check-result`.

## AWS Budgets

Alerts on actual or forecasted spend, plus RI/SP utilization and coverage thresholds.

### Templates Worth Setting Up

1. **Monthly account budget** — alert at 50% / 80% / 100% of forecast.
2. **Service-specific budget** — top spending service per team.
3. **RI utilization alert** — alert if utilization drops below 90%.
4. **RI coverage alert** — alert if coverage drops below 70%.
5. **SP utilization + coverage** — same thresholds.
6. **Daily spend anomaly** — alert if a day's spend exceeds N% of trailing-week average.
7. **Sandbox kill-switch** — Budget Action: at 100%, apply a restrictive SCP or stop all EC2/RDS in the account.

Budgets cost $0.02/day per budget after the first 2.

### Budget Actions

Automate response when a budget is breached:
- Apply IAM policy / SCP
- Stop EC2 / RDS instances
- Trigger SNS / Lambda / SSM automation

Use sparingly — actions on prod accounts are dangerous; reserve for sandboxes.

## Cost Anomaly Detection

Free, ML-based. Sits inside Cost Explorer. Detects unusual spend patterns at service or linked-account level.

- **Recommended monitors:**
  - One per AWS service (or service category).
  - One per linked account.
- **Alert subscription:** SNS or email; route SNS to Slack via Lambda.
- **Tune thresholds** to reduce noise: percentage delta + absolute delta floor.

## Pulling It Together — A Reasonable FinOps Stack

For a mid-size AWS account:

1. **CUR + Athena + CUDOS dashboard** as the source of truth.
2. **Compute Optimizer** enabled org-wide.
3. **AWS Budgets** for monthly spend, RI/SP utilization+coverage, sandbox kill-switches.
4. **Cost Anomaly Detection** monitors per service and per account.
5. **Cost-allocation tags** enabled on `Owner`, `Environment`, `CostCenter`.
6. **Quarterly reservation review** cycle, driven by `scripts/reservation-coverage.sh` + Cost Explorer recommendations.
7. **Monthly waste sweep** with `scripts/find-idle-resources.sh`.
