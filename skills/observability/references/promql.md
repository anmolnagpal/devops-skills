# PromQL patterns for review and alerting

Load this when writing alert rules, or when judging whether an existing rule measures
what its name claims.

## The four signals, as expressions

**Traffic.** Always a `rate` over a counter, never the counter itself:

```promql
sum by (service) (rate(http_requests_total[5m]))
```

**Errors.** As a ratio, so it survives traffic changes:

```promql
sum(rate(http_requests_total{code=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))
```

**Latency.** From a histogram, at a quantile, and note the argument order:

```promql
histogram_quantile(0.99,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
)
```

**Saturation.** Against the hard limit, not against an arbitrary number:

```promql
# Memory as a fraction of the container's own limit.
container_memory_working_set_bytes{container!=""}
  / on(pod, container) kube_pod_container_resource_limits{resource="memory"}
```

## Mistakes that make a rule lie

**`rate` on a gauge.** `rate` and `increase` only make sense on counters. On a gauge
they produce numbers that look plausible and mean nothing. Use the gauge directly, or
`deriv` if you genuinely want slope.

**Quantile of a quantile.** `avg(histogram_quantile(...))` across pods is not a
percentile of anything. Aggregate the buckets first, then take the quantile:

```promql
# Wrong: averages each pod's p99.
avg(histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])))

# Right: one p99 across all pods.
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
```

**`sum by (le)` omitted.** `histogram_quantile` needs the `le` label. Aggregating it
away, or grouping by something else and dropping `le`, yields `NaN` and an alert that
can never fire. This is the single most common broken alert in a Prometheus setup,
because a rule that never fires looks exactly like a service that never breaks.

**Range shorter than twice the scrape interval.** `rate(x[15s])` with a 30s scrape has
fewer than two samples and returns nothing. Rule of thumb: range at least 4x the scrape
interval.

**Division with no guard.** When traffic drops to zero the denominator is zero and the
ratio is `NaN`, so the alert stops firing during a total outage. Guard it:

```promql
(sum(rate(http_requests_total{code=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))) > 0.02
and sum(rate(http_requests_total[5m])) > 0.1
```

Or alert separately on traffic having vanished, which is usually the more important
signal:

```promql
sum(rate(http_requests_total{service="checkout"}[10m])) == 0
```

**Label mismatch in binary operations.** `a / b` matches on all labels by default, so
one extra label on either side silently produces an empty result. Use
`on(...)` or `ignoring(...)` explicitly whenever the two sides come from different
exporters.

## Kubernetes workload expressions

```promql
# Crash looping.
increase(kube_pod_container_status_restarts_total{container="app"}[15m]) > 3

# OOM kills specifically, which restarts alone will not tell you.
increase(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[30m]) > 0

# Pods not ready, excluding those legitimately completing.
sum by (namespace, pod) (
  kube_pod_status_phase{phase!~"Succeeded|Running"}
) > 0

# CPU throttling, which shows up as latency long before it shows up as an error.
rate(container_cpu_cfs_throttled_periods_total[5m])
  / rate(container_cpu_cfs_periods_total[5m]) > 0.25

# Deployment stuck mid-rollout.
kube_deployment_status_replicas_updated
  != kube_deployment_spec_replicas
```

The throttling one is worth adding to most services. A pod at its CPU limit is not
failing, it is slow, and the latency SLO degrades with nothing in the error rate to
explain it.

## Recording rules

Precompute anything an alert and a dashboard both use. It reduces query cost and, more
usefully, keeps the two from drifting into different definitions of the same metric:

```yaml
groups:
  - name: checkout.slis
    interval: 30s
    rules:
      - record: service:request_error_ratio:rate5m
        expr: |
          sum by (service) (rate(http_requests_total{code=~"5.."}[5m]))
            / sum by (service) (rate(http_requests_total[5m]))
```

Naming convention is `level:metric:operation`. Alerts then read
`service:request_error_ratio:rate5m{service="checkout"} > 0.02`, which is checkable at a
glance in a way the expanded form is not.

## Reviewing someone else's alert rule

In order, because each question invalidates the ones after it:

1. **Can it fire at all?** Missing `le` in a `histogram_quantile`, a label that does not
   exist, a metric name that was renamed by an exporter upgrade. Ask when it last fired.
2. **Does it fire on a symptom or a cause?** CPU at 80% is a cause and belongs on a
   dashboard. Users seeing errors is a symptom and belongs on a pager.
3. **Is there a `for:` clause proportional to the window?** A 5m range with `for: 30s`
   pages on a single bad scrape.
4. **Does the threshold come from anywhere?** A round number nobody can source is a
   number that gets tuned by silencing.
5. **Does it survive zero traffic?** See the `NaN` case above.
6. **Does it have a `runbook_url`?** Without one the alert hands over a puzzle.
