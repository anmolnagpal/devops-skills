# bad-tf-module-no-readme

Repo-shaped, because `TF-QUAL-002` is about a directory rather than a file: the
finding is a module with no `README.md`, and no single `.tf` can express that.

`modules/orders-queue/` has five described inputs, two outputs, and a dead-letter
queue whose relationship to the primary queue a caller cannot infer from variable
names. That is exactly the case a README earns: `visibility_timeout` and
`retention_seconds` interact, and nothing states how.

`modules/labels/` must NOT be reported. It is one file computing one string from two
inputs, which is exclusion 10: a README there would restate the variable
descriptions. The pair is the point, since a rule that fires on every directory
without a README is a per-directory tax that gets switched off.

Nothing else may fire in either module: every variable and output is described and
typed, both queues are KMS-encrypted, tags are threaded from the caller rather than
hardcoded, and neither module declares a backend (correct for a module, and the
documented `TF-STATE-001` exemption).

`TF-RES-002` must also stay silent. An SQS queue is not in the stateful set the rule
names, and its messages are in flight rather than at rest.
