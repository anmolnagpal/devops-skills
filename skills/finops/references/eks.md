# EKS Cost Optimization Reference

EKS is one of the highest-leverage FinOps targets in most accounts because three different cost domains stack: control plane, compute (nodes), and the workload itself. Plus support resources: load balancers, EBS for PVs, NAT for image pulls, observability.

## Where EKS Costs Come From

| Component | Cost driver |
|---|---|
| **EKS control plane** | Flat $0.10/hour per cluster (~$73/month). Sub-cluster waste — fewer larger clusters > many small. |
| **Worker nodes (EC2)** | Instance hours + EBS for node disks + container image storage. Usually largest line item. |
| **Worker nodes (Fargate)** | Per-pod vCPU + memory + ephemeral storage by the second. Higher per-unit but no idle. |
| **EBS for PVs** | Per-GB provisioned, not used. PVCs left after pod deletion still cost. |
| **Load balancers (ALB/NLB)** | Per-LB hourly + LCU/data. Service of type LoadBalancer = one LB per service unless using Ingress. |
| **NAT Gateway** | Image pulls from public registries through NAT can be huge. ECR pull-through cache + VPC Endpoints fix this. |
| **Cross-AZ data** | Pod-to-pod traffic across AZs ($0.01/GB each way). Service mesh + multi-AZ default = silent cost. |
| **CloudWatch Logs / Container Insights** | Ingestion fees compound at pod-log scale. Often the second-biggest CW Logs source after Lambda. |
| **AMP / AMG (managed Prometheus / Grafana)** | Per-sample ingestion + storage. Easy to over-collect. |

## High-Leverage Wins (in rough order of impact)

### 1. Karpenter for Node Provisioning

Karpenter is the modern node provisioner — faster, smarter bin-packing, better Spot handling than Cluster Autoscaler. Single biggest EKS cost lever in most accounts.

- **Replaces Cluster Autoscaler + managed node groups** for most workloads.
- **Just-in-time provisioning:** picks the cheapest instance that fits the pending pods.
- **Diversified Spot** by default — across families and AZs reduces interruption rate.
- **Consolidation:** continuously replaces underutilized nodes with cheaper ones.
- **Scale to zero:** when no pods are scheduled to a NodePool, nodes are removed entirely.

Minimal NodePool example:

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: [amd64, arm64]                      # Allow Graviton
        - key: karpenter.sh/capacity-type
          operator: In
          values: [spot, on-demand]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: [c, m, r]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]                               # Modern generations only
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
  limits:
    cpu: "1000"
```

Key knobs:
- **`capacity-type: [spot, on-demand]`** — prefer Spot, fall back to OD when Spot unavailable.
- **Allow `amd64` *and* `arm64`** — lets Karpenter pick Graviton when image supports it. Build multi-arch images.
- **`consolidationPolicy: WhenEmptyOrUnderutilized`** — aggressive, recommended for stateless workloads. Use `WhenEmpty` only for clusters with mostly stateful workloads.
- **`limits`** — hard caps on what Karpenter will provision, as a runaway-cost guard.

### 2. Spot for Stateless Tiers

EKS workers on Spot can be ~70% cheaper. With Karpenter handling diversification + replacement, interruption tolerance is much improved.

**Safe for Spot:**
- Stateless web tiers behind a Service (PDBs + multiple replicas)
- Batch / Job workloads with checkpointing
- CI runners (GitHub Actions, Argo Workflows, Tekton)
- Anything with a `Deployment` and proper `terminationGracePeriodSeconds`

**Avoid Spot for:**
- StatefulSets (especially with local storage)
- Single-replica services without retry tolerance
- Workloads with very long startup or graceful-shutdown windows

Use **node affinity + topology spread** to avoid concentrating an entire workload on Spot nodes from the same instance pool.

### 3. Right-Size Pod Requests

Most pod `resources.requests` are guesses copied from old YAML. Karpenter (and the scheduler) bin-packs based on requests, so **over-requested pods waste node capacity directly**.

**Workflow:**
- Install **Vertical Pod Autoscaler (VPA)** in *recommendation-only* mode.
- Or use **Goldilocks** for a UI on top of VPA.
- Or use **AWS Compute Optimizer for ECS-on-Fargate / EKS** (newer feature, see Compute Optimizer console).
- Apply recommendations in batches; watch for OOM/CPU throttling regressions.

**Common over-request offenders:** Java apps with 4 GiB requested, using 800 MiB. Sidecars (envoy, fluent-bit) requesting 200m CPU each in pods that have 50 sidecars per node.

### 4. HPA + KEDA for Workload Autoscaling

Pods that scale match nodes that scale. Without HPA, you're paying for peak-sized fleets at all times.

- **HPA on the right metric.** Default CPU often lags real load. Use:
  - HTTP RPS (via Prometheus Adapter)
  - SQS queue depth, Kafka lag, Redis stream length (KEDA)
  - Custom application metrics
- **KEDA** for event-driven autoscaling and scale-to-zero (HPA can't scale to zero without KEDA).
- **Scheduled scaling** (KEDA cron scaler) for known patterns — drop replicas at night.

### 5. Graviton Migration

Switch worker node families from `m5`/`c5`/`r5` to `m6g`/`c6g`/`r6g`. ~20% cheaper, often higher per-vCPU performance.

- **Karpenter:** add `arm64` to `kubernetes.io/arch` requirements (above).
- **Container images:** build multi-arch with `docker buildx build --platform linux/amd64,linux/arm64`. Most languages work; check native deps.
- **Roll out gradually:** add a Graviton-only NodePool, taint it, opt workloads in via tolerations, then remove the taint when stable.

### 6. ALB Ingress Controller (One LB, Many Services)

Each `Service: type=LoadBalancer` provisions a separate ELB ($16-22/month minimum each). Aggregate via **AWS Load Balancer Controller + Ingress** so one ALB serves many services via host/path rules.

- 1 ALB for `*.internal.example.com` with 50 ingress rules → $22/month
- 50 NLBs → $1100/month

Use **`alb.ingress.kubernetes.io/group.name`** annotation to share an ALB across multiple Ingress resources.

### 7. ECR Pull-Through Cache + VPC Endpoints

Image pulls from Docker Hub / GHCR / Quay through NAT Gateway ($0.045/GB processing) add up fast on big clusters.

- **ECR pull-through cache** — caches public images in a private ECR repo. Pulls go through ECR (cheaper, faster, rate-limit-free).
- **VPC Interface Endpoints for ECR + ECR-Docker + S3 (gateway):** image pulls bypass NAT entirely.
- **VPC Gateway Endpoint for S3** — ECR image layers live in S3, so this is essential.

For a 100-node cluster pulling 5 GB of images per restart, this can save $200-500/month in NAT processing alone.

### 8. CloudWatch Container Insights — Tune Down

Container Insights is convenient but expensive at scale. Common waste:

- **Default agent ships every metric for every container.** Filter aggressively.
- **Enhanced observability** (newer feature) — much more granular but multiplies cost. Enable per-namespace, not cluster-wide.
- **Application logs to CloudWatch by default** — cheaper to ship to S3 (FluentBit → S3 + Athena) for retention; CloudWatch only for hot/recent logs.

For most teams: Prometheus (or AMP) for metrics, S3 for log archive, CloudWatch only for short-retention operational logs. Check the bill — Container Insights + CW Logs are often >30% of EKS-related cost.

### 9. PVC Hygiene

- **`reclaimPolicy: Delete`** on dynamic StorageClasses → PVCs deleted when the resource is removed. Default for managed gp3 SC.
- **Audit `Released` PVs** — these stay around if `reclaimPolicy: Retain`.
- **gp3 over gp2** for the EBS CSI driver (set as default StorageClass).
- **Right-size PVC requests.** Same dynamic as pod requests — over-requested = wasted EBS.

### 10. Fargate vs EC2 Decision

EKS Fargate is per-pod (vCPU + memory + storage by the second). Higher per-unit cost but zero idle.

**Fargate wins for:**
- Bursty, low-utilization workloads (sub-30% average)
- System pods (kube-proxy not applicable; CoreDNS, EBS CSI controller — but check if Fargate is supported per pod)
- Per-tenant isolation (one Fargate profile per tenant)
- Workloads with strict node-level security/compliance requirements

**EC2 + Karpenter wins for:**
- Sustained high utilization (>60% across the cluster)
- Anything that benefits from Spot
- Workloads that need DaemonSets, hostPath, or specific instance hardware

Many clusters use both: Fargate profiles for system/control workloads, Karpenter EC2 for the application tier.

**Note:** Fargate is covered by **Compute Savings Plans** — buy one if Fargate spend is meaningful (>$1k/month).

### 11. Cluster Sprawl

Each EKS cluster has a $73/month control plane fixed cost. More importantly: each cluster has its own observability stack, ingress controllers, monitoring agents, system pods → these dominate at low scale.

**Consolidate:** prefer namespaces + RBAC + NetworkPolicies + ResourceQuotas over separate clusters. A 10-cluster org collapsed to 3 large multi-tenant clusters can cut $700/month in control planes alone, plus 10x in deduplicated system overhead.

**Don't over-consolidate:** keep separate clusters for prod/non-prod and for genuinely different security domains. Latency-sensitive and bursty workloads may also justify separation.

## Cost-Visibility Tooling for EKS

Per-namespace / per-team cost attribution requires extra setup — the AWS bill only sees node-level cost.

### Kubecost (or AWS-managed equivalent: Kubernetes Cost Monitoring in CloudWatch)

- Joins Kubernetes resource usage with AWS pricing → **per-namespace, per-deployment, per-pod cost**.
- Free Open Source tier covers single-cluster with limited retention.
- AWS offers Amazon CloudWatch Container Insights with cost monitoring (basic).
- **OpenCost** (CNCF, Kubecost-derived) is a fully open alternative.

### Tagging at the Workload Level

EKS doesn't propagate Kubernetes labels to AWS resources by default. Options:

- **Karpenter NodeClass** has a `tags` field — tag nodes by NodePool / team / environment.
- **EBS CSI Driver** has `extra-tags` parameter — tag dynamically provisioned EBS by namespace.
- **AWS Load Balancer Controller** propagates `alb.ingress.kubernetes.io/tags` to provisioned ALBs.

Combine with **cost-allocation tags** activated in the billing console for `Cluster`, `Namespace`, `Team`, `Owner`.

## Reservations for EKS

EKS workloads are reservable like any EC2 workload — use **Compute Savings Plans** for the steady baseline:

1. Measure steady-state cluster compute spend (EC2 nodes + Fargate together) over 30 days.
2. Buy a **1yr No Upfront Compute SP** covering ~70% of that baseline. Compute SP applies to both EC2 nodes and Fargate pods, in any region, any family.
3. Let Karpenter handle the variable +30%.
4. Re-evaluate quarterly as Graviton migration / scale changes.

**Don't:**
- Buy zonal RIs for EKS — Karpenter will move pods around AZs based on Spot availability and you'll never hit utilization targets.
- Buy EC2 Instance SP for a Karpenter cluster unless the NodePool is locked to a single instance family (defeats Karpenter's purpose).

See `reservations.md` for full SP/RI details.

## Quick EKS Cost Audit Checklist

When asked to audit EKS cost, walk through:

- [ ] Karpenter installed and configured with Spot + ARM allowed? (Or still using CA + managed node groups?)
- [ ] Pod `requests` audited via VPA/Goldilocks? Any glaring over-requests?
- [ ] HPA on workloads, scaling on the right metric?
- [ ] One ALB per Ingress group, or one LB per service?
- [ ] ECR pull-through cache + VPC endpoints for ECR/S3?
- [ ] CloudWatch Container Insights tuned, not default-everything?
- [ ] gp3 default StorageClass? Released PVs cleaned up?
- [ ] Fargate vs EC2 split appropriate to utilization profile?
- [ ] Compute Savings Plan covering steady baseline?
- [ ] Cluster count justified, or sprawl?
- [ ] Cross-AZ pod chatter understood (Kubecost / VPC flow logs)?

For deeper diagnostics, point Kubecost or OpenCost at the cluster and review the namespace ranking. The top 3 namespaces almost always drive >70% of cost.
