# bad-obs-blind-service

A **repo-shaped** fixture rather than a single file, which is the only way this
skill's absence rules can be tested honestly. Four of these five findings are
"there is no X anywhere", and a claim like that cannot be made from one file
handed over in isolation. The whole tree is here, so absence is verifiable.

Two services in prod, and no signal leaves either of them:

- `OBS-MON-001` — no `ServiceMonitor`, no `prometheus.io/scrape` annotation, no
  metrics port, and no `/metrics` handler in `ledger-api/internal/server.go`.
  Nothing collects a metric. Exclusion 1 does not apply: there is no central
  scrape config, no agent, and no platform repo named anywhere in the tree.
- `OBS-LOG-001` — `checkout-api/internal/logging.go` writes to a rotating file on
  the container filesystem with no shipper, no sidecar, and no mounted volume. The
  logs die with the pod. This is the exact inverse of exclusion 4: stdout plus a
  collector would be correct, and a file with no collector is the finding.
- `OBS-TRC-001` — `ledger_client.go` calls `ledger-api` over HTTP on every
  settlement, so a single user request crosses a process boundary. No OTel SDK, no
  `traceparent`, not even a request ID. Exclusion 3 explicitly does not apply once
  there are two services, and this fixture has two on purpose.
- `OBS-DASH-001` — no dashboard JSON, no Grafana provisioning, no dashboard
  ConfigMap, and nothing named in the README.
- `OBS-SLO-001` — no SLI, no target, no error budget, no burn-rate rules. These
  are user-facing payment services, so exclusion 7 does not rescue it.

`OBS-MON-002` must NOT fire, and this is the subtle one. There are no alert rules
at all, so there is nothing whose route could be traced to a receiver. The rule is
about a page that never reaches a human; here the correct finding is that nothing
is measured in the first place (`OBS-MON-001`), and reporting both would be
double-counting one gap. A skill that reports `OBS-MON-002` here has confused
"nothing to alert on" with "alerting is broken".

`OBS-LOG-002` must NOT fire either: retention applies to a log destination, and
this repo has no destination to set retention on.

The Helm values are deliberately correct on every non-observability axis (replicas,
probes, limits, labels, securityContext, ClusterIP, token automount off) so a run
that reports a k8s rule here has drifted outside this skill's catalog.
