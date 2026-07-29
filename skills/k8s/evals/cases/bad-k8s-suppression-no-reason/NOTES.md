# bad-k8s-suppression-no-reason

`k8s-skill:ignore SEC-SEC-001` with no `-- reason`, above a live Stripe key
committed in values.

Both fire: `META-SUP-001` for the unreasoned suppression and `SEC-SEC-001` for the
plaintext secret, because a suppression missing its reason does not suppress
anything.

`clean-suppressed-plaintext-secret` in this suite proves the same rule can be
suppressed correctly when a reason is given. This case proves the reason is load
bearing rather than decorative, on the one rule where getting it wrong publishes a
production credential.

Everything else is prod-clean so no other rule fires: three replicas, empty tag
set at deploy, all three labels, full securityContext, requests and limits with
memory limit equal to request, both probes, ClusterIP, token automount off.
