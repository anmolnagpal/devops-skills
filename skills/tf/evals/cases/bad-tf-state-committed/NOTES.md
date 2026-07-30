# bad-tf-state-committed

A committed `terraform.tfstate`. One finding, and it is the reason the rule exists
rather than a style preference: state files carry resolved values, and anything
sensitive that passed through a resource is in there in plain text along with real
account IDs and resource identifiers. Committing one also guarantees the next
`apply` fights the remote backend over which state is authoritative.

`TF-STATE-003` must fire even though the configuration itself declares a correct
remote S3 backend with locking. The two facts are independent: the backend says
where state *should* live, and the committed file proves a copy also lives here.
A skill that reads the backend block and concludes state is handled misses it.

Everything else is deliberately clean so nothing else fires: pinned versions,
`locals` tags, described and typed variables, a described output, and an
`aws_flow_log` covering the VPC so `SEC-LOG-002` stays silent.

`SEC-LOG-001` must also stay silent here. This module provisions network only, and
per exclusion 8 a CloudTrail absence is judged against a configuration that would
plausibly contain one; a single-purpose network module is not that. The pair of this
case and `bad-tf-public-bucket-no-audit-logs` is what holds that line: the other one
is a platform root module where the absence does count.
