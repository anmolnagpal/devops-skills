# bad-obs-unbounded-logs

Two of three log groups never expire, by two different routes:

- `app` omits `retention_in_days` entirely.
- `audit` sets it to `0`, which reads like a deliberate value but is AWS's
  encoding of "never expire". This is the one a reviewer skims past.

Both are `OBS-LOG-002`, consolidated into one finding per the repeats rule, and
the finding must name both resources.

`debug` at 7 days must NOT be reported: retention is set and short, which is the
correct treatment for a chatty stream.

`OBS-LOG-001` must NOT fire: these groups are the centralized destination. Their
existence is evidence logging is centralized, which is exactly the distinction
between the two logging rules.

Fixture is prod (`/aws/eks/prod-payments/...`), so the dev relaxation does not
apply. `OBS-LOG-002` is also the one rule this skill still reports in dev, since
an unbounded dev log group bills the same as a prod one.
