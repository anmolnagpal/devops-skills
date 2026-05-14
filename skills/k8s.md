---
name: k8s
description: "Kubernetes and Helm review and scaffolding for EKS workloads. Use when user says 'review my helm values', 'before I deploy', 'scaffold a new service', 'check values.yaml', or when working in values.yaml, Chart.yaml, or Helm template files."
metadata:
  version: 1.1.0
  author: Anmol Nagpal
  category: devops
  updated: 2026-04-16
paths:
  - "**/values*.yaml"
  - "**/Chart.yaml"
  - "**/templates/*.yaml"
  - "**/templates/*.yml"
allowed-tools:
  - Glob
  - Read
---

# Kubernetes / EKS Skill

Review Helm values before EKS deployments or scaffold production-ready values for a new service — enforcing team standards for security, HA, and resource management.

## Keywords
kubernetes, k8s, eks, helm, values.yaml, chart, pod, deployment, service, ingress, secrets, resources, probes, replicas, irsa, iam, ecr, namespace, container, image, liveness, readiness, hpa, autoscaling

## Output Artifacts

| Request | Output |
|---------|--------|
| `/k8s review` | Blocking / advisory issue list with file:line references |
| `/k8s new <service>` | Production-ready `values.yaml` and `Chart.yaml` stub |

---

## Step 1 — Determine the action

Read the arguments provided:

- `review` or `review <env>` → go to **REVIEW**
- `new <service-name>` → go to **NEW**
- No arguments → use Glob to check the current directory, then:
  - If `values.yaml` or `Chart.yaml` exists → ask: "I can see Helm files here. Do you want to **review** (pre-deploy check) or create something **new**?"
  - If the directory is empty → default to **NEW** and ask for the service name

---

## REVIEW — Pre-Deploy Helm Check

Run before every EKS deployment. Find and read all values files (`values.yaml`, `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml`, `Chart.yaml`) and any `templates/` files if present.

**Target environment:** Use the argument if provided. Otherwise infer from the file being reviewed, or ask.
Production and staging checks are stricter than dev.

### Secrets
- Never put plaintext secrets, passwords, tokens, API keys, or credentials in `values.yaml`
- Fields like `password`, `secret`, `token`, `apiKey`, `privateKey` must reference a Kubernetes Secret:

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: my-service-secrets
        key: db-password
```

- Prefer external-secrets operator for pulling secrets from AWS Secrets Manager

### Image
- Never use `latest` or an empty string as the image tag
- Image tag must always be set at deploy time via `--set image.tag=$IMAGE_TAG`
- Set `tag: ""` in `values.yaml` as a placeholder — never a real value
- Use `imagePullPolicy: IfNotPresent` for immutable tags; `Always` only for mutable tags

### Resource limits
Always set both requests and limits for every container:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

Memory limit must not be less than memory request.

### Health probes
Always configure both probes with explicit timing:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 15
  failureThreshold: 3
```

### Replica count
- Minimum `replicaCount: 2` for staging and production
- `replicaCount: 1` is only acceptable for dev environments

### Required labels
Every workload must have these labels:

```yaml
commonLabels:
  app: <service-name>
  env: <environment>
  team: <team-name>
```

### Security context
Always set on pods:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
```

### AWS access from pods
Use IAM Roles for Service Accounts (IRSA) — never mount static AWS credentials:

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

### Review output format

```
BLOCKING — Must fix before deploy
----------------------------------
[values.yaml:14] Hardcoded secret: db_password has inline value → use secretKeyRef
[values.yaml:3]  Image tag: tag is set to "latest" → use a specific version tag

ADVISORY — Should fix
----------------------
[values.yaml:22] Security context: runAsNonRoot not set → add securityContext.runAsNonRoot: true

Summary: 2 blocking issue(s), 1 advisory issue(s). Fix blocking issues before deploying.
```

If reviewing environment-specific overrides, assess the merged result for the target environment — not just the base `values.yaml`.

---

## NEW — Scaffold Helm Values for a New Service

### Identify the service name
Extract from the argument. If not provided, ask: "What is the service name?"

### Ask targeted questions (max 5)
1. What type of workload? (web service with HTTP / background worker / cron job)
2. Container image repository? (e.g. `123456789.dkr.ecr.eu-west-1.amazonaws.com/my-service`)
3. Does it expose an HTTP port? If yes, which port?
4. Any environment variables or secrets? (list them — we'll wire them up correctly)
5. Rough resource size: small (0.1 CPU / 128Mi) / medium (0.5 CPU / 512Mi) / large (1 CPU / 1Gi)?

Wait for answers before generating files.

### Generated `values.yaml`

```yaml
# Service: <service-name>
# Generated with /k8s new — validate with /k8s review before deploying

replicaCount: 2

image:
  repository: <from answer>
  tag: ""           # Always set at deploy time: --set image.tag=$IMAGE_TAG
  pullPolicy: IfNotPresent

commonLabels:
  app: <service-name>
  team: ""          # Set via CI: --set commonLabels.team=$TEAM
  env: ""           # Set via CI: --set commonLabels.env=$ENV

service:
  type: ClusterIP
  port: <from answer>
  targetPort: <from answer>

resources:
  requests:
    cpu: <from size>
    memory: <from size>
  limits:
    cpu: <2x requests cpu>
    memory: <same as requests memory>

readinessProbe:
  httpGet:
    path: /health
    port: <port>
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: <port>
  initialDelaySeconds: 30
  periodSeconds: 15
  failureThreshold: 3

env: []
# - name: LOG_LEVEL
#   value: "info"

envFrom: []
# - secretRef:
#     name: <service-name>-secrets

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: <service-name>

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

serviceAccount:
  create: true
  annotations: {}
  # For IRSA:
  # annotations:
  #   eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

### Generated `Chart.yaml`

```yaml
apiVersion: v2
name: <service-name>
description: Helm chart for <service-name>
type: application
version: 0.1.0
appVersion: "0.1.0"
```

End with:
```
Next steps:
1. Update image.repository with your ECR URL
2. Configure secrets via Kubernetes Secrets or external-secrets
3. Update /health paths in readinessProbe and livenessProbe
4. For IRSA: create the IAM role and add ARN to serviceAccount.annotations
5. Run /k8s review before your first deploy
```
