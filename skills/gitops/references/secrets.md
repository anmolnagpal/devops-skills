# Secrets in a GitOps repo

Load this when a repo has no secret mechanism, or when choosing between the three that
exist. The rule itself is `SEC-SEC-001`: a plaintext `Secret` in a GitOps repo makes the
repo and its entire history the blast radius.

## Choosing

| | external-secrets | SOPS | Sealed Secrets |
|---|---|---|---|
| Secret lives in | AWS Secrets Manager / Parameter Store / Vault | the Git repo, encrypted | the Git repo, encrypted |
| Rotation | change it in the store, no commit | re-encrypt and commit | re-seal and commit |
| Who can read it | anyone with IAM access to the store | anyone with the age or KMS key | only the in-cluster controller |
| Works with Flux natively | via the operator | yes, decrypts in-controller | via the operator |
| Works with Argo CD | via the operator | needs a plugin or a pre-render step | via the operator |
| Breaks if | the store is unreachable at sync time | the key is lost | the controller's key is lost and not backed up |
| Best for | EKS with IRSA, anything already using Secrets Manager | small teams, few secrets, no cloud secret store | clusters with no external secret store |

**Default recommendation on EKS: external-secrets.** Rotation without a commit is the
property that matters most in practice, because a mechanism where rotating a credential
requires a pull request is a mechanism where credentials do not get rotated. It also
pairs with IRSA, so no static credential is needed to fetch the secrets.

**SOPS is the right answer for small repos** with a handful of secrets and no cloud
secret store, and it is the only one of the three that Flux decrypts natively with no
extra operator.

**Sealed Secrets** is fine, with one operational caveat that is easy to miss: the
controller's private key is the only thing that can decrypt every sealed secret in the
repo. Losing the cluster without a backup of that key means re-sealing everything from
the original plaintext, which you may no longer have.

## external-secrets on EKS

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: checkout
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets        # IRSA-annotated, no static credentials
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: checkout-secrets
  namespace: checkout
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: checkout-secrets                # the k8s Secret it creates
    creationPolicy: Owner
  data:
    - secretKey: STRIPE_SECRET_KEY
      remoteRef:
        key: prod/checkout/stripe
        property: secret_key
    - secretKey: DATABASE_URL
      remoteRef:
        key: prod/checkout/database
        property: url
```

The repo contains references only. Nothing secret is committed, and the review question
becomes "does this IAM role have access to more secrets than this service needs", which
is a much better question than "who has read this repo".

Two review notes on this pattern:

- `refreshInterval` is how long a rotated secret takes to reach the cluster. It does not
  restart pods, so an app that reads its secret once at boot needs a reloader
  (`stakater/Reloader`, or a checksum annotation) or the rotation has no effect.
- `creationPolicy: Owner` means deleting the ExternalSecret deletes the Secret. With
  Argo prune in play, that is a deletion path worth knowing about.

## SOPS with Flux

```bash
# Encrypt in place. Only the values are encrypted; keys stay readable so diffs work.
sops --encrypt --in-place --age age1ql3z7... deploy/base/secret.yaml
```

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: checkout
  namespace: flux-system
spec:
  interval: 10m
  path: ./deploy/overlays/prod
  prune: true
  sourceRef:
    kind: GitRepository
    name: checkout
  decryption:
    provider: sops
    secretRef:
      name: sops-age                     # the age key, seeded out of band
```

`--encrypt-regex '^(data|stringData)$'` keeps metadata readable, which is what makes a
SOPS-encrypted file reviewable in a pull request: you can see which keys changed without
seeing the values.

## Reviewing a repo's secret handling

1. **Grep for the obvious first.** `kind: Secret` with `stringData` or `data` that is
   not `sops`-encrypted and not an ExternalSecret target. That is `SEC-SEC-001`.
2. **Check the history, not just HEAD.** A secret removed in a later commit is still in
   the repo. `git log -p --all -S 'stringData'` finds it. Removal requires rotation, not
   just a commit, and saying so is part of the finding.
3. **Check what the mechanism protects.** An ExternalSecret pulling from a store where
   the whole team has `secretsmanager:GetSecretValue` on `*` has moved the problem
   rather than solved it.
4. **Check the ordering.** The secret machinery must land before the workloads that
   mount it. `sync-wave: 0` for the SecretStore and ExternalSecret, `1` for the
   Deployment, or the first sync fails on a missing Secret and looks like a flake.
5. **Check for a rotation path.** If rotating a credential requires a commit, a review,
   and a sync, expect that it has never happened. Ask when it last did.

## What not to accept

- A `Secret` "encrypted" with base64. `data:` is base64 by definition and is not
  encryption.
- Secrets in a Helm `values.yaml` committed alongside the chart. Same rule, different
  filename.
- A `.gitignore` entry as the control. The file exists on someone's laptop and one
  `git add -f` away from the repo.
- "It is a private repo." Private is an access-control boundary, not an encryption
  boundary, and it does not survive a fork, a leaked token, or an offboarding you did
  not notice.
