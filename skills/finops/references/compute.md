# AWS Compute Cost Reference

Right-sizing, instance family selection, Spot strategy, Graviton, Auto Scaling, Fargate vs EC2, Lambda tuning.

## Right-Sizing EC2

**Use Compute Optimizer first** (free). It analyzes 14 days of CloudWatch + memory metrics and gives concrete recommendations with projected savings. Available via console, API, or `aws compute-optimizer get-ec2-instance-recommendations`.

### What "right-sized" means

A workload is right-sized when, over a representative period:
- p95 CPU is between **40-70%**
- p95 memory is between **50-80%**
- Network and EBS bandwidth aren't pinned

Below those bands → over-provisioned (downsize). Above → at-risk (upsize or scale out).

### Action playbook

| Compute Optimizer finding | What to do |
|---|---|
| Over-provisioned | Downsize one step. Test in non-prod. Watch p95 for a week before declaring victory. |
| Under-provisioned | Upsize, *or* scale horizontally if the workload supports it (cheaper at scale). |
| Optimized | Leave it. Move on to the next instance. |

### Don't right-size before reserving

Reserve *after* sizing settles. An RI on a `m5.4xlarge` is wasted if you downsize to `m5.2xlarge` next month.

## Instance Family Selection

| Family prefix | Use for |
|---|---|
| `t3` / `t4g` (burstable) | Dev, low-traffic prod, burstable workloads. **Watch CPU credits** — sustained high CPU costs extra (`unlimited` mode) or throttles (`standard` mode). |
| `m` (general) | Balanced default. `m6i` (Intel), `m6a` (AMD, ~10% cheaper), `m6g`/`m7g` (Graviton, ~20% cheaper). |
| `c` (compute) | CPU-bound (encoding, batch, web tier). |
| `r` (memory) | Caches, in-memory DBs, large JVMs. |
| `i` / `d` | NVMe-backed (databases, analytics). |
| `g` / `p` / `inf` / `trn` | GPU/ML. |

**Generation rule:** newer generations are almost always cheaper per unit of work. `m6` < `m5` < `m4`. Audit anything still on `*4` or older.

## Graviton (ARM)

`*g` instances run on AWS Graviton (ARM64). Roughly 20% cheaper than equivalent x86, often higher performance per dollar.

**Easy wins:**
- Managed services: RDS, ElastiCache, OpenSearch, MemoryDB, MSK — flip a switch, no app changes.
- Lambda: change `Architectures` to `arm64` if dependencies support it.

**Requires effort:**
- EC2 / EKS / Fargate: container images must be built for `linux/arm64`. Most modern languages (Go, Rust, Node, Python, Java, .NET 6+) work; check native dependencies. Use `docker buildx build --platform linux/amd64,linux/arm64`.

Migrate **before** reserving — a Graviton RI is a different SKU than an x86 RI.

## Spot Instances

Up to **90% off** On-Demand. AWS reclaims with 2-minute warning when capacity is needed.

**Good fits:**
- Stateless web tiers behind an LB (with mixed-instance ASG)
- Batch jobs, CI runners, data pipelines (with checkpointing)
- Kubernetes worker nodes for non-critical workloads (with Karpenter or Cluster Autoscaler)
- Dev/test environments

**Bad fits:**
- Single-instance services with no replacement strategy
- Workloads that can't tolerate a 2-minute interruption
- Very long-running stateful jobs without checkpointing

**Patterns:**
- **EKS + Karpenter** with `spot` in capacity types is the cleanest spot story today. Karpenter handles diversification and replacement.
- **EC2 Auto Scaling Mixed Instances Policy:** specify multiple instance types and a Spot/On-Demand split.
- **EC2 Fleet / Spot Fleet:** for large batch workloads, allows price-capacity-optimized allocation across many pools.

**Reduce interruptions:** diversify across instance families and AZs. Use `capacity-optimized` allocation strategy. Avoid the cheapest pool — it's also the most contested.

## Auto Scaling Cost Patterns

- **Scale on the right metric.** Default CPU often lags real load. Use ALB request count, SQS queue depth, or custom metrics for queue/event-driven workloads.
- **Predictive scaling** for cyclical traffic (business-hours apps, regional SaaS). Pre-warms before the spike instead of catching up after.
- **Scheduled actions** for known patterns: scale dev/test ASGs to 0 nights and weekends.
- **Warm pools** for slow-booting AMIs: cheaper than running idle, faster than full launch.
- **Step scaling** with cooldowns to avoid flapping (each scale-in/out cycle costs in stability and sometimes pricing rounding).

## Fargate vs EC2 (for ECS/EKS)

Fargate is simpler but per-hour more expensive. Rough breakeven:

- **Bursty, low average utilization** (sub-30%): Fargate cheaper after factoring ops time.
- **Sustained high utilization** (>60% across the cluster): EC2 + bin-packing cheaper.
- **Mixed:** EKS with managed node groups + Fargate profiles for system pods.

**Fargate Spot** exists (~70% off) for ECS interruption-tolerant tasks. EKS Fargate has no Spot equivalent.

**Fargate is covered by Compute Savings Plan** — get one if Fargate spend is meaningful.

## Lambda Cost Tuning

Lambda is billed on `(GB-seconds)` + `(requests)`. The biggest lever is **memory size**, which also scales CPU.

- **Use AWS Lambda Power Tuning** (open-source state-machine tool) to find the cost-optimal memory setting per function. For CPU-bound functions, *more* memory often costs *less* total because runtime drops faster than memory grows.
- **arm64 architecture** ~20% cheaper. Switch unless a native dep blocks it.
- **Provisioned Concurrency** is expensive — only use for latency-critical paths, and cover it with a Compute Savings Plan.
- **Cold starts:** use SnapStart (Java/Python/.NET) — free, big startup latency reduction; sometimes lets you drop Provisioned Concurrency entirely.
- **Avoid idle Lambdas in VPC** with Provisioned Concurrency on — that's the most expensive Lambda configuration.

## Off-Hours Scheduling

Non-prod environments stopped 12 hours/day + weekends → **~70% reduction** on those workloads.

Options:
- **AWS Instance Scheduler** (official solution; CFN template).
- **Lambda + EventBridge:** simple per-tag start/stop. ~30 lines of Python.
- **EKS Karpenter:** scales worker nodes to 0 when no pods are scheduled.
- **Tag convention:** `Schedule=mon-fri-9-18` consumed by the scheduler.

Pair with a `Schedule=24x7` opt-out tag for things that must stay up.
