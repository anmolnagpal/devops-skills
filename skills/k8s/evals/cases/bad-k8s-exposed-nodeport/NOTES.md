# bad-k8s-exposed-nodeport

Three findings, three different mechanisms:

- `SEC-K8S-006` — `type: NodePort` with an explicit `nodePort: 31820`. Opens that
  port on every node; with the default EKS node security group that is reachable
  from anything in the VPC, and from the internet wherever node SGs are permissive.
  No internal-LB annotation, no auth-terminating ingress, so exclusion 8 does not
  apply.
- `SEC-K8S-007` — `automountServiceAccountToken: true` on a static brochure site
  that has no reason to talk to the API server, and `SESSION_SIGNING_KEY` handed
  over as a literal `env[].value` instead of a `secretKeyRef`.
- `SEC-SEC-001` — the same signing key is a plaintext secret in values, which is
  the pre-existing rule and fires independently.

`SEC-K8S-002` must NOT fire: no host namespaces, no `hostPath`, not privileged.
`SEC-K8S-004` must NOT fire: bare values file, no `templates/`, exclusion 7.
