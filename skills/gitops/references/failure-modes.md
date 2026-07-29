# Diagnosing GitOps failures

Load this when asked why a controller deleted, reverted, or refused to sync something.
Organised by symptom, because that is what you are handed.

## "Argo deleted my resources"

Almost always prune acting on an empty or shrunken render. Work through these in order:

**1. Did the render return nothing?** `prune: true` with `allowEmpty: true` means an
empty render is a valid desired state, so everything goes. Causes:

- `path` no longer exists after a repo restructure. Argo reports sync succeeded.
- A Kustomize or Helm error that yields zero manifests rather than failing.
- An ApplicationSet generator returning no elements, which deletes every generated
  Application, which prunes every resource they owned. One bad generator, whole
  environment.

```bash
argocd app get <app> --show-operation
argocd app manifests <app> | head        # empty output is the answer
```

**2. Did the resource lose its owner?** Argo prunes what it previously tracked and no
longer sees. Renaming a resource in Git is a delete plus a create, and with
`PrunePropagationPolicy=foreground` the delete completes first.

**3. Was it a `finalizers` interaction?** An Application with
`resources-finalizer.argocd.argoproj.io` deletes its resources when the Application
itself is deleted. Deleting an Application to "stop managing" a service removes the
service.

**4. Did `selfHeal` revert a manual fix rather than delete it?** Different symptom,
same surprise: someone patched a resource during an incident, and the next
reconciliation put it back.

Prevention, in the order that actually helps:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
    allowEmpty: false          # the single most valuable line here
  syncOptions:
    - PruneLast=true           # prune only after new resources are healthy
    - PrunePropagationPolicy=foreground
```

Plus `Prevent Deletion` on anything stateful:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: Delete=false,Prune=false
```

## "It syncs forever" / OutOfSync immediately after a successful sync

The controller and the cluster disagree about what the manifest means, so every
reconciliation sees a diff. Usual causes:

- **A mutating admission webhook** (Istio sidecar injection, Vault agent injector,
  policy engines) adds fields Argo then wants to remove.
- **Defaulted fields** the API server fills in and the manifest omits.
- **HPA owns `replicas`** while the manifest also specifies it. The two fight forever.

The fix is `ignoreDifferences`, scoped as narrowly as possible:

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas                    # HPA owns this
    - group: ""
      kind: Service
      jqPathExpressions:
        - '.spec.ports[] | select(.nodePort != null) | .nodePort'
```

For HPA specifically, removing `replicas` from the manifest entirely is better than
ignoring it: then only one thing owns the field.

Diagnose with:

```bash
argocd app diff <app>                       # what it thinks differs
argocd app get <app> -o json | jq '.status.conditions'
```

## "Sync fails on first apply but succeeds on retry"

Ordering. A CRD and a resource of that kind applied in the same pass, or a namespace and
something in it. The retry works because the CRD landed on the first attempt before
failing on the consumer.

Argo uses waves; Flux uses `dependsOn`. Waves run ascending, and resources within a wave
apply together:

| Wave | Contents |
|---|---|
| `-2` | namespaces, CRDs |
| `-1` | operators and controllers owning those CRDs |
| `0` | platform services (ingress, cert-manager issuers, external-secrets) |
| `1` | application workloads |
| `2` | consumers of the workloads (dashboards, alerts, jobs) |

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
```

`Replace=true` and `ServerSideApply=true` are the other two knobs worth knowing: the
first for resources too large for the annotation-based last-applied-configuration, the
second for CRDs that exceed the annotation size limit entirely.

## "The Application is Healthy but the app is broken"

Health is per-resource and Argo's default assessment is generous. A Deployment with
`replicas: 3` and 3 ready pods is Healthy even if every pod is serving 500s. Argo
health does not know about your service.

This is why `OBS-MON-002` matters alongside GitOps: sync health is a deployment signal,
not an availability signal, and treating a green Argo dashboard as an availability
dashboard is a category error.

## Flux equivalents

| Symptom | Argo | Flux |
|---|---|---|
| Deleted resources | `prune` + `allowEmpty` | `Kustomization.spec.prune: true` with a source resolving empty |
| Ordering | `sync-wave` | `dependsOn` |
| Ignore drift | `ignoreDifferences` | `spec.patches` or removing the field |
| Stuck reconcile | `argocd app get` | `flux get all -A`, `kubectl describe kustomization` |
| Force a run | `argocd app sync` | `flux reconcile kustomization <name> --with-source` |
| Suspend | `argocd app set --sync-policy none` | `flux suspend kustomization <name>` |

Flux specifics worth knowing:

- **`spec.wait: true`** makes a Kustomization wait for health before dependents run.
  Without it, `dependsOn` only waits for *applied*, not *ready*, which reintroduces the
  ordering race it was meant to solve.
- **`spec.timeout`** with `wait: true`, or a stuck reconciliation blocks the dependency
  chain indefinitely.
- **`spec.force: true`** recreates immutable-field resources instead of failing. It is a
  destructive flag with a reassuring name.
- **Interval is not latency.** `interval: 10m` on a GitRepository means up to 10 minutes
  before a commit is noticed. Use a webhook receiver if that matters.

## First commands, either controller

```bash
# Argo CD
argocd app get <app>
argocd app history <app>
argocd app diff <app>
kubectl -n argocd logs deploy/argocd-application-controller --tail=200

# Flux
flux get all -A
flux logs --all-namespaces --since=30m
kubectl -n flux-system describe kustomization <name>
kubectl -n flux-system describe gitrepository <name>
```

`argocd app history` is the one people forget, and it is usually the fastest route to
"what changed": it lists every sync with its revision, so you can pin the incident to a
commit before reading any logs.
