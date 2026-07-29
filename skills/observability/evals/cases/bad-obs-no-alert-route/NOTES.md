# bad-obs-no-alert-route

The case that a naive check gets wrong. A `PrometheusRule` exists, it is
well-formed, it has a `for:` window and a `runbook_url`. Counting files would call
this alerting present.

It is not. The rule's labels are `team: payments`, and the only non-default route
in `alertmanager.yml` matches `team = "platform"`. Everything else falls through
to `receiver: "null"`, which has no config of any kind. The page goes nowhere, so
`OBS-MON-002` fires. This is why the skill is told to trace rule labels to a route
to a real receiver rather than to check that rules exist.

`OBS-MON-001` must NOT fire: the `ServiceMonitor` selects `app: checkout-api` and
carries the `release: kube-prometheus-stack` label the operator needs, so
collection genuinely works.

`OBS-TRC-001`, `OBS-DASH-001`, `OBS-SLO-001` must NOT fire: this fixture is a
monitoring-config directory, not a service repo. There is no request path to
trace and no service whose SLO could be judged, so per the confidence gate the
skill should stay silent rather than assume absence.
