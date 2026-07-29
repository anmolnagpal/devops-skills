# SLO arithmetic and burn-rate alerts

Load this when defining an SLO, choosing burn-rate thresholds, or explaining why an
alert threshold should be a particular number.

## Error budget, in minutes

The budget is the allowed unavailability. Say it in minutes, because a percentage is
abstract and a number of minutes ends the argument.

Over a 30-day window (43,200 minutes):

| Target | Budget per 30 days | Per week | Per day |
|---|---|---|---|
| 99% | 7h 12m | 1h 41m | 14m 24s |
| 99.5% | 3h 36m | 50m 24s | 7m 12s |
| 99.9% | 43m 12s | 10m 5s | 1m 26s |
| 99.95% | 21m 36s | 5m 2s | 43s |
| 99.99% | 4m 19s | 1m | 8.6s |
| 99.999% | 26s | 6s | 0.9s |

Two things fall out of this table that are worth saying to anyone choosing a target:

**99.99% is 4 minutes 19 seconds a month.** That is less than one rolling deploy that
goes wrong. It is not reachable with manual intervention anywhere in the recovery path,
because a human cannot be paged, wake up, and act inside four minutes.

**Each extra nine costs roughly ten times more.** Going 99.9% to 99.99% is not a
tightening, it is a different architecture: no single-region dependencies, automated
failover, and no human in the loop.

## The SLI comes first

An SLO without a measurable SLI is a number in a document. The SLI is a ratio of good
events to valid events, and both halves need defining.

```promql
# Availability: fraction of requests that were not server errors.
sum(rate(http_requests_total{service="checkout",code!~"5.."}[5m]))
  / sum(rate(http_requests_total{service="checkout"}[5m]))
```

Decisions hiding in that expression, all worth making explicitly:

- **4xx excluded from bad.** A client sending malformed input is not your outage. But
  a 429 from your own rate limiter probably is, and a 401 caused by your auth service
  failing definitely is. Decide per code, not per class.
- **Health checks excluded from valid.** Probe traffic inflates the denominator and
  makes the ratio look better during an outage, precisely when it matters.
- **Batch and internal traffic separated.** A retrying background job can dominate the
  denominator and hide user-facing failure entirely.

Latency SLIs are ratios too, not averages. "p99 under 300ms" is not an SLI; "99% of
requests complete in under 300ms" is:

```promql
sum(rate(http_request_duration_seconds_bucket{service="checkout",le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count{service="checkout"}[5m]))
```

This needs `le="0.3"` to be an actual bucket boundary in your histogram. If it is not,
you are interpolating, and the number is softer than it looks.

## Burn rate

Burn rate is how fast you are consuming budget relative to sustainable. Burn rate 1
exhausts the budget exactly at the window's end. Burn rate 2 exhausts it in half the
window.

```
burn_rate = observed_error_ratio / (1 - target)
```

At a 99.9% target, `1 - target` is 0.001. A 2% error rate is a burn rate of 20: the
month's budget is gone in 36 hours.

## Multi-window, multi-burn-rate alerts

One threshold cannot serve both a total outage and a slow leak. The standard pairing,
from the Google SRE workbook, tuned so each alert has a useful detection time and
neither fires on noise:

| Purpose | Burn rate | Long window | Short window | Severity | Budget consumed when it fires |
|---|---|---|---|---|---|
| Fast burn | 14.4 | 1h | 5m | page | 2% |
| Medium burn | 6 | 6h | 30m | page | 5% |
| Slow burn | 3 | 1d | 2h | ticket | 10% |
| Very slow burn | 1 | 3d | 6h | ticket | 10% |

The short window is an `and` condition, not decoration. It exists so the alert
**resolves** promptly once the burn stops. Without it, a 1-hour window keeps the alert
firing for an hour after recovery, and people learn to ignore it.

```yaml
- alert: CheckoutErrorBudgetFastBurn
  expr: |
    (
      1 - (
        sum(rate(http_requests_total{service="checkout",code!~"5.."}[1h]))
        / sum(rate(http_requests_total{service="checkout"}[1h]))
      )
    ) > (14.4 * 0.001)
    and
    (
      1 - (
        sum(rate(http_requests_total{service="checkout",code!~"5.."}[5m]))
        / sum(rate(http_requests_total{service="checkout"}[5m]))
      )
    ) > (14.4 * 0.001)
  for: 2m
  labels:
    severity: page
    team: payments
  annotations:
    summary: "checkout burning error budget 14.4x faster than sustainable"
    runbook_url: "https://runbooks.example.com/checkout/error-budget"
```

Two severities across the four rows is the point. Fast and medium burn page; slow burn
files a ticket. A team where every burn-rate alert pages at 03:00 learns to silence the
lot, and then the fast-burn alert is gone too.

## Low-traffic services

Burn-rate alerting assumes enough events for a ratio to mean something. At 10 requests
per minute, a single error is a 10% error rate for that minute and every threshold
above trips constantly.

Options, in order of preference:

1. **Lengthen the windows.** 6h/30m instead of 1h/5m. Slower detection, but the
   detection you get is real.
2. **Alert on absolute counts** instead of ratios below a traffic floor:
   `increase(errors_total[30m]) > 5`.
3. **Aggregate related services** into one SLO where they share a user journey.
4. **Accept that you cannot page on this** and rely on a daily budget report. Honest,
   and better than an alert nobody trusts.

Adding a traffic guard to a ratio alert is the usual compromise:

```promql
and sum(rate(http_requests_total{service="checkout"}[1h])) > 1
```

## Reviewing an existing SLO

Questions that find the real problems, roughly in order of how often they land:

1. **Is the denominator honest?** Health checks, retries, and internal traffic in
   `valid` events is the most common way an SLO reports green through an outage.
2. **Does the window match the business?** A 30-day rolling window and a monthly
   billing cycle disagree about when the budget resets.
3. **Do the alert thresholds derive from the target?** A 5% threshold under a 99.9%
   target is a burn rate of 50, which fires long after the budget is gone.
4. **Is there a `for:` clause?** Without one, a 30-second blip pages someone.
5. **Does anything happen when the budget is exhausted?** An SLO with no consequence
   is a dashboard. The consequence is usually a freeze on feature deploys until the
   budget recovers, and it needs agreeing before the first breach, not during it.
6. **Who agreed to the target?** An SLO engineering set alone is a guess about what
   users tolerate.
