# AWS Networking Cost Reference

Data transfer is one of the most under-monitored cost categories. NAT Gateways, cross-AZ traffic, internet egress, and inter-region replication regularly drive 10-30% of an AWS bill in network-heavy accounts.

## Data Transfer Cost Matrix (US-region illustrative)

| Source → Destination | Cost |
|---|---|
| Same AZ, same VPC, private IP | **free** |
| Same AZ, same VPC, public/EIP | $0.01/GB each way |
| Cross-AZ, same region (private) | $0.01/GB each way |
| Cross-region | $0.02/GB out (varies by region pair) |
| To internet | $0.05–$0.09/GB (tiered, first 10 TB/mo most expensive) |
| Inbound from internet | **free** |
| To/from CloudFront edge | free between AWS services and CloudFront |
| Through NAT Gateway | $0.045/GB **processing** + standard egress on top |
| Through VPC Endpoint (Interface) | $0.01/GB processing (no NAT processing fee) |
| Through VPC Endpoint (Gateway: S3, DynamoDB) | **free** |

**Read this twice:** NAT Gateway data processing is on top of egress — every GB through a NAT to the internet costs **NAT processing + egress**, not either-or.

## NAT Gateway — The Usual Top Networking Cost

A single NAT Gateway has a fixed hourly cost (~$0.045/hour ≈ $33/month) **plus** $0.045/GB processed. In high-egress accounts, the GB charge dwarfs the hourly charge.

### Reduce NAT Gateway Cost

1. **VPC Gateway Endpoints for S3 and DynamoDB.** Free. Routes S3/DynamoDB traffic via the VPC route table without crossing the NAT. Single biggest NAT optimization for most accounts.
2. **VPC Interface Endpoints (PrivateLink) for ECR, Secrets Manager, SSM, KMS, CloudWatch Logs, STS, etc.** $7.30/endpoint/month + $0.01/GB processed. Worth it if traffic to those services is significant.
3. **Collapse to one NAT per region** (instead of per-AZ HA) for non-prod. Trade some HA for ~67% NAT hourly cost reduction.
4. **NAT Instance** (self-managed EC2 NAT) for low-traffic non-prod. ~$5/month for a `t4g.nano` vs $33/month for managed NAT, but you own the HA + patching.
5. **Audit egress destinations.** A NAT processing huge volumes to a single endpoint may justify a Direct Connect, PrivateLink, or VPC peering.

### Detect Heavy NAT Traffic

VPC Flow Logs → Athena. Top destinations by bytes through the NAT subnets reveal whether the traffic is to AWS services (fixable with endpoints) or external (different solution).

## Cross-AZ Traffic

Every byte between AZs costs $0.01/GB **each way** ($0.02/GB round trip).

### Where it adds up

- **Multi-AZ databases** with cross-AZ replication writes (RDS Multi-AZ, Aurora replicas in different AZs, ElastiCache Redis replication).
- **Service mesh / chatty microservices** spread across AZs.
- **Application Load Balancers** — by default, ALB cross-zone load balancing is **on** and **free**; NLB cross-zone is **off** by default and **paid** when on.
- **Kubernetes pods** scheduled across AZs talking to each other.

### Mitigations

- **Topology-aware routing** (k8s `service.kubernetes.io/topology-mode: Auto` or Istio locality LB). Keeps service-to-service traffic in the same AZ when possible.
- **Single-AZ deployments for non-prod.** Trade HA for cost.
- **Co-locate cache + app** in the same AZ (with replicas elsewhere).

Don't over-optimize — collapsing to single AZ removes the AZ-level fault tolerance you're paying for. Trade-offs apply per environment.

## Internet Egress

Tiered, US-region (illustrative):
- First 10 TB/mo: $0.09/GB
- Next 40 TB: $0.085/GB
- Next 100 TB: $0.07/GB
- Over 150 TB: $0.05/GB
- Inbound is free.

### Reduce Egress Cost

1. **CloudFront in front of S3 / ALB.** Egress from CloudFront is cheaper ($0.085/GB tier 1 in US) **and** AWS-to-CloudFront is free. For static + cacheable content, savings stack with cache hit rates.
2. **CloudFront Security Savings Bundle / Committed-use discounts** for high CloudFront spend.
3. **Compression** at the edge (CloudFront, ALB).
4. **Image/video optimization** — most accounts ship larger assets than necessary.
5. **AWS Direct Connect** for sustained high egress to a known on-prem destination (>$10k/month internet egress probably justifies the math).

## Cross-Region

$0.02/GB outbound (varies).

- **Audit cross-region replication.** S3 CRR, DynamoDB Global Tables, Aurora Global Database, EBS snapshot copies — easy to set up and forget.
- **Filter S3 CRR by prefix or tag** instead of replicating entire buckets.
- **Use VPC Peering or Transit Gateway for VPC-to-VPC**, but watch out: TGW has a $0.05/hour per attachment + $0.02/GB processing on top of cross-region transfer.

## VPC Peering vs Transit Gateway

| | Peering | Transit Gateway |
|---|---|---|
| Hourly cost | none | $0.05/hour per attachment |
| Data processing | none beyond standard transfer | $0.02/GB |
| Topology | mesh | hub-and-spoke |

Rule of thumb: **fewer than ~5 VPCs → peering**; more than that → TGW for management ease, but be aware of the per-attachment hourly + processing cost.

## CloudFront Pricing Notes

- **Origin shield** + tiered origins reduce origin requests. Worth enabling for high-RPS origins.
- **Functions vs Lambda@Edge:** Functions are ~10x cheaper for simple header/URI manipulations. Use Lambda@Edge only when you need Node/Python execution.
- **Real-time logs** are pricey ($0.01 per million log lines + Kinesis). Use standard CloudFront logs (free, delivered to S3) unless real-time is required.

## ELB

- **ALB** charges per LCU (a metered unit covering connections, requests, bandwidth, rule evaluations). Idle ALBs still cost ~$16/month minimum. **Audit and delete idle ALBs.**
- **NLB** has lower per-unit cost but cross-zone is paid (off by default).
- **Classic Load Balancers** — migrate; ALB/NLB are cheaper and more capable.

## VPN / Direct Connect

- **Site-to-Site VPN:** $0.05/hour per VPN connection + standard data transfer. Two tunnels per connection, both billed.
- **Client VPN:** $0.10/hour per associated subnet + $0.05/hour per connected client. Heavy usage adds up; consider IAM Identity Center + AWS Verified Access alternatives for some use cases.
- **Direct Connect:** port hours + $0.02/GB egress. Pays off vs internet egress at scale.
