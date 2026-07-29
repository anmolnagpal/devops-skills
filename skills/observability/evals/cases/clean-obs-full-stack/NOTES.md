# clean-obs-full-stack

Nothing may fire. Each pillar is present in a form the rules accept:

- `OBS-LOG-001` — logs to stdout with a cluster collector, which is exclusion 4
  and the correct pattern, not a gap.
- `OBS-LOG-002` — retention lives with the log group in the infra repo, and the
  comment names where. Exclusion 5.
- `OBS-MON-001` — metrics endpoint plus a `ServiceMonitor` carrying the operator's
  `release` label.
- `OBS-MON-002` — rules enabled and labelled `team: data-platform`, with the route
  and receiver named in the comment. Contrast with `bad-obs-no-alert-route`, where
  the label matches nothing.
- `OBS-TRC-001` — suppressed with a reason, and the reason is also a valid
  exclusion 3 on its own merits. This case doubles as proof the
  `observability-skill:ignore` convention is honored, including that a suppression
  **with** a reason must not raise `META-SUP-001`.
- `OBS-DASH-001` — dashboard shipped as a ConfigMap.
- `OBS-SLO-001` — SLI expression, target, and window all stated.

The `slo.availability.target` of 99.5 rather than a rounder 99.9 is deliberate:
the skill must not grade the *ambition* of an SLO, only whether one exists.
