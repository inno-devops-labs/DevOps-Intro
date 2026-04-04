# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Service Overview

#### AWS — Amazon Elastic Container Registry (ECR) + AWS CodeArtifact

AWS splits artifact management across two services:

**Amazon ECR** is the primary container and OCI artifact registry. It supports Docker images, OCI images, Helm charts (via OCI), and supply-chain artifacts (SBOMs, signatures). Key features:
- **Vulnerability scanning**: Basic (on-push, CVE feeds) or Enhanced (continuous via Amazon Inspector v2, includes language-level dependencies)
- **Cross-region & cross-account replication** via configurable replication rules
- **Pull-through cache**: proxy images from Docker Hub, Quay, GitHub GHCR, ACR, and others with no extra charge beyond storage/transfer
- **Lifecycle policies**: rule-based automated cleanup by age, tag status, or count
- **Encryption**: AES-256 or KMS customer-managed keys
- **AWS PrivateLink** support for VPC-private access
- **ECR Archive** (Nov 2025): cost-reduced storage tier for rarely accessed images; restore takes ~20 min

**AWS CodeArtifact** handles language packages: npm, PyPI, Maven, NuGet, RubyGems, Swift. It proxies public registries (npmjs.com, PyPI, Maven Central, etc.) and provides IAM-based access control with CloudTrail audit logging.

#### GCP — Artifact Registry

GCP consolidates container images and all language package formats into a single service. It replaced the deprecated Google Container Registry (fully shut down in 2025). Supported formats:
- Docker/OCI images, Helm charts, Maven, npm, PyPI, Go modules, Ruby gems, Apt/RPM packages, and generic artifacts
- **Three repository modes**: Standard (private storage), Remote (pull-through cache from upstream public registries), and Virtual (aggregated view across multiple repos with priority ordering)
- **Vulnerability scanning** via Artifact Analysis API: on-push, on-demand, and continuous re-scan using OSV database; also detects embedded secrets
- **SLSA provenance & Sigstore/cosign** attestation support for supply-chain security
- **Multi-regional repositories** (e.g., `us`, `europe`, `asia`) for low-latency global access
- **Cleanup policies**: automated deletion of old/untagged artifacts
- **VPC Service Controls** for security perimeters

#### Azure — Azure Container Registry (ACR) + Azure Artifacts

Azure also splits the responsibilities: **ACR** handles Docker/OCI container images and Helm charts (OCI-only since Sep 2025); **Azure Artifacts** (part of Azure DevOps) handles npm, NuGet, Maven, PyPI, and Universal Packages.

ACR has three tiers with increasing capabilities:

| Feature | Basic | Standard | Premium |
|---|---|---|---|
| Included storage | 10 GiB | 100 GiB | 500 GiB |
| Geo-replication | No | No | Yes |
| Private endpoints | No | No | Yes |
| Content trust / CMEK | No | No | Yes |
| Artifact cache (pull-through) | No | Yes | Yes |
| Retention policies | No | No | Yes |
| Artifact streaming | No | No | Yes |
| Webhooks | 2 | 10 | 500 |

Additional ACR capabilities:
- **ACR Tasks**: cloud-based Docker builds triggered by Git commits or base image updates, without a local Docker daemon
- **Vulnerability scanning** via Microsoft Defender for Containers (continuous, agentless)
- **Connected registries**: offline-capable edge/IoT deployments (Premium)
- **Azure Entra ID RBAC** and repository-scoped tokens for access control

---

### Comparison Table

| Dimension | AWS ECR | GCP Artifact Registry | Azure ACR |
|---|---|---|---|
| Container images | Yes | Yes | Yes |
| Language packages | Separate service (CodeArtifact) | Yes (unified) | Separate service (Azure Artifacts) |
| Helm charts | Yes (OCI) | Yes (OCI) | Yes (OCI) |
| OS packages (Apt/RPM) | No | Yes | No |
| Vulnerability scanning | Basic (free) / Enhanced (Inspector pricing) | Via Artifact Analysis API (billed separately) | Via Defender for Cloud (billed separately) |
| Continuous re-scan | Yes (Enhanced) | Yes | Yes |
| Multi-region replication | Yes (all tiers) | Yes (multi-regional repos) | Yes (Premium only) |
| Pull-through cache | Yes | Yes (Remote repos) | Yes (Standard+) |
| Base monthly fee | None | None | $5–$50/month by tier |
| Storage cost | $0.10/GB/month | $0.10/GB/month (0.5 GB free) | Included in tier |
| Language package storage | $0.05/GB (CodeArtifact) | Included in Artifact Registry | Included in Azure Artifacts |
| Cross-region transfer | Standard AWS rates | $0.01–$0.15/GB by region pair | Azure bandwidth rates |
| Free tier | 500 MB private (12 mo) + 50 GB public (always) | 0.5 GB/month (always) | Included in tier |
| CI/CD build integration | CodeBuild/CodePipeline | Cloud Build | ACR Tasks / Azure Pipelines |
| Kubernetes integration | ECS, EKS, Lambda | GKE, Cloud Run | AKS, ACI |

---

### Analysis: Multi-Cloud Registry Strategy

For a **multi-cloud strategy**, **GCP Artifact Registry** is the most compelling single service due to its unified model — one API, one IAM framework, one pricing page covering containers, Helm, npm, Maven, PyPI, Go, Apt, and RPM. Eliminating the need for a separate package service simplifies pipeline configuration and audit trail management.

However, in practice a multi-cloud strategy implies deploying workloads on multiple clouds, where each cloud's native registry offers the tightest integration:

- **ECR** is optimal for AWS-heavy workloads: free intra-region data transfer to ECS/EKS/Lambda and deep Inspector integration make it operationally efficient at scale.
- **Artifact Registry** is optimal for GCP: Workload Identity eliminates key management for GKE pulls, and the unified format support reduces tool sprawl.
- **ACR Premium** is optimal for large Azure AKS deployments needing geo-replication across Azure regions.

A pragmatic multi-cloud approach uses each provider's native registry for runtime image pulls (minimizing cross-cloud transfer costs) while optionally mirroring critical images to a neutral OCI-compatible registry (e.g., GitHub Container Registry) for portability. GCP Artifact Registry's breadth makes it the strongest candidate if only one registry service is allowed.

---

## Task 2 — Serverless Computing Platform Research

### Service Overview

#### AWS Lambda

The most mature and widely adopted serverless FaaS platform. Key characteristics:

- **Runtimes**: Node.js 22, Python 3.13, Java 21, .NET 8, Ruby 3.3, Go (custom runtime), PowerShell 7 — plus custom runtimes via provided.al2023; supports container images up to 10 GB
- **Architectures**: x86_64 and ARM64 (Graviton2 — 20% cheaper compute, faster cold starts)
- **Memory**: 128 MB – 10,240 MB (CPU scales proportionally)
- **Timeout**: max **15 minutes**
- **Concurrency**: 1,000 per region (default, can be raised); Reserved and Provisioned Concurrency for predictable scaling
- **Cold starts**: Node.js/Python ~200–400 ms typical; Java/NET ~500 ms–7 s without SnapStart; SnapStart (Java/Python/.NET) reduces to ~90–200 ms via snapshot restore; VPC cold starts <100 ms via HyperPlane ENI
- **Pricing**: $0.20/1M requests + $0.0000166667/GB-s (x86) or $0.0000133334/GB-s (ARM64); free tier: 1M requests + 400,000 GB-s/month (permanent)
- **Triggers**: API Gateway, Function URLs, S3, DynamoDB Streams, SQS, SNS, EventBridge, Kinesis, ALB, and 200+ event sources via EventBridge Pipes

#### GCP Cloud Run (and Cloud Run Functions)

In August 2024, Google merged Cloud Functions into Cloud Run. What was formerly Cloud Functions 2nd gen is now **Cloud Run functions** — deployed on Cloud Run infrastructure. Cloud Functions 1st gen is still available but receives no new features.

- **Runtimes**: Node.js, Python, Go, Java, .NET, PHP, Ruby — plus any container image for Cloud Run services
- **Instance sizing**: 0.08–8 vCPUs, up to 32 GiB RAM per instance
- **Timeout**: up to **60 minutes** (services); up to **24 hours** (Cloud Run Jobs)
- **Concurrency**: up to 1,000 requests per instance (default 80); no fixed regional cap
- **Cold starts**: ~200 ms–2 s for interpreted runtimes; higher for JVM/compiled; mitigated by setting minimum instances (charged at idle rate)
- **Pricing**: $0.40/1M requests + $0.000024/vCPU-s + $0.0000025/GiB-s; free tier: 2M requests + 180,000 vCPU-s + 360,000 GiB-s/month (permanent)
- **Triggers**: HTTP, Eventarc (Pub/Sub, Cloud Storage, Firestore, Audit Logs), Cloud Scheduler

Key differentiator: Cloud Run supports **request concurrency within a single instance**, which can dramatically reduce the number of instances (and cold starts) needed for concurrent workloads compared to Lambda's per-request isolation model.

#### Azure Functions

Microsoft's FaaS offering with the widest set of workflow orchestration capabilities via Durable Functions.

- **Runtimes**: C#/.NET 8/9/10, Node.js 22, Python 3.12, Java 21, PowerShell 7.4 (all on isolated worker model; in-process .NET model EOL Nov 2026)
- **Hosting plans**:
  - **Consumption** (legacy): auto-scales to zero; max 1,536 MB memory; 10-min timeout; worst cold starts
  - **Flex Consumption** (GA 2025): fixed 2 GB or 4 GB instance sizes; 30-min timeout; improved cold start profile; pre-provisioned instances
  - **Elastic Premium**: pre-warmed instances, effectively eliminating cold starts; unlimited timeout; no per-execution charge
  - **Dedicated (App Service)**: always-on VMs, highest cost, no cold starts
- **Timeout**: 10 min (Consumption) / 30 min default, unlimited max (Premium/Dedicated); HTTP responses hard-capped at **230 seconds** regardless of plan
- **Cold starts (Consumption)**: Node.js/Python 1–5 s; C#/.NET 2–10 s; PowerShell 4–27 s — notably higher than AWS Lambda and GCP Cloud Run
- **Durable Functions**: stateful, long-running orchestration extension; supports fan-out/fan-in, chaining, async polling, human interaction workflows; timers can run for years; backed by durable-task-scheduler (new 2025)
- **Pricing (Consumption)**: $0.20/1M executions + $0.000016/GB-s; free tier: 1M executions + 400,000 GB-s/month (permanent)
- **Triggers**: HTTP, Event Grid, Service Bus, Event Hubs, Blob/Queue Storage, Cosmos DB change feed, Timer, and more

---

### Comparison Table

| Dimension | AWS Lambda | GCP Cloud Run | Azure Functions |
|---|---|---|---|
| Node.js | Yes (22.x) | Yes | Yes (22.x) |
| Python | Yes (3.13) | Yes | Yes (3.12) |
| Java | Yes (21) | Yes | Yes (21) |
| Go | Yes (custom runtime) | Yes (native) | No (custom handler only) |
| Ruby | Yes (3.3) | Yes | No |
| PHP | No (custom runtime) | Yes | No |
| .NET / C# | Yes (.NET 8) | Yes | Yes (.NET 8/9/10) |
| PowerShell | Yes | No | Yes (7.4) |
| Container images | Yes (up to 10 GB) | Yes | Yes |
| Max memory | 10,240 MB | 32 GiB | 1,536 MB (Consumption) |
| Max timeout | 15 min | 60 min (services) | 10 min (Consumption) / unlimited (Premium) |
| Max concurrency | 1,000/region (default) | 1,000/instance, unlimited instances | Scales with demand |
| Concurrency model | 1 request per instance | Up to 1,000 requests per instance | 1 request per instance (HTTP) |
| Cold start (Node/Python) | 200–400 ms | 200 ms–2 s | 1–5 s |
| Cold start (Java/.NET) | 90–200 ms (SnapStart) | 1–5 s | 2–10 s |
| Cold start mitigation | SnapStart / Provisioned Concurrency | Min instances | Elastic Premium plan |
| Pricing: per 1M requests | $0.20 | $0.40 | $0.20 |
| Pricing: compute | $0.0000133–0.0000167/GB-s | $0.000024/vCPU-s + $0.0000025/GiB-s | $0.000016/GB-s |
| Free tier (requests/month) | 1M | 2M | 1M |
| Free tier (compute/month) | 400,000 GB-s | 180,000 vCPU-s + 360,000 GiB-s | 400,000 GB-s |
| Stateful workflows | Step Functions (separate) | Workflows (separate) | Durable Functions (built-in) |
| Max deployment package | 250 MB (zip) / 10 GB (container) | No limit (container) | 500 MB (zip) |
| VPC support | Yes | Yes | Yes |
| ARM/Graviton | Yes (20% cheaper) | No | No |

---

### Analysis: Serverless Platform for a REST API Backend

For a **REST API backend**, **AWS Lambda** is the strongest choice for most production scenarios:

1. **Cold start performance**: Lambda on ARM64 with SnapStart (for JVM/.NET) delivers the most consistent cold starts (~90–200 ms for SnapStart, 200–400 ms for Node.js/Python) — significantly better than Azure Functions on Consumption, and comparable to or faster than GCP Cloud Run for most runtimes.
2. **HTTP integration**: Lambda Function URLs or API Gateway provide mature, low-latency HTTP routing with WAF, caching, rate limiting, and auth integration (Cognito, IAM, custom authorizers).
3. **Pricing**: Lambda ARM64 is the cheapest compute option at scale; combined with the 1M requests free tier, it covers most small-to-medium APIs at zero cost.
4. **Ecosystem maturity**: the broadest set of triggers, the most SDK integrations, and the most operational tooling (X-Ray, CloudWatch Insights, Lambda Powertools) make Lambda the most production-ready option.

**GCP Cloud Run** is the better choice when:
- The application already uses containers (no need to fit into Lambda deployment packaging constraints)
- Workloads are bursty with many concurrent requests per invocation (the per-instance concurrency model reduces instance count and cost)
- Go or PHP is the target runtime (native support vs. Lambda custom runtimes)
- Long-running requests exceed 15 minutes

**Azure Functions** is the better choice when:
- The team is standardized on Azure and .NET/C#
- Stateful, long-running workflows are needed alongside simple HTTP endpoints (Durable Functions eliminates the need for a separate orchestration service)
- PowerShell-based automation endpoints are required

---

### Reflection: Advantages and Disadvantages of Serverless Computing

#### Advantages

- **Zero infrastructure management**: no OS patching, capacity planning, or cluster management; the provider handles scaling, availability, and runtime updates
- **True scale-to-zero**: no charges when idle; cost correlates directly with usage, making it economical for low-traffic or intermittent workloads
- **Auto-scaling**: scales from zero to thousands of concurrent executions in seconds without pre-provisioning
- **Reduced operational overhead**: developers focus on business logic rather than infrastructure, shortening time-to-production
- **Built-in high availability**: functions run across multiple availability zones automatically

#### Disadvantages

- **Cold starts**: the first invocation after an idle period incurs a startup penalty (from ~200 ms to several seconds depending on runtime and provider), which can violate latency SLOs for latency-sensitive APIs
- **Execution duration limits**: maximum timeouts (15 min on Lambda, 10 min on Azure Consumption) make serverless unsuitable for long-running computations without architectural workarounds
- **Vendor lock-in**: event trigger APIs, SDK bindings, and deployment models are provider-specific; migrating between providers requires significant refactoring
- **Observability complexity**: distributed tracing across hundreds of short-lived function invocations is harder than tracing a long-lived service; cold-start noise makes latency percentiles difficult to interpret
- **Limited local resources**: constrained memory (especially Azure Consumption at 1,536 MB), ephemeral disk, and no persistent in-memory state require external storage for any stateful operation
- **Concurrency limits**: default regional concurrency caps (e.g., Lambda's 1,000) can cause throttling under unexpected traffic spikes if not proactively raised
- **Debugging and testing**: reproducing the exact cloud execution environment locally is non-trivial; integration tests require mocking or running against live cloud resources

---

## Sources

**Artifact Registries:**
- [Amazon ECR Pricing](https://aws.amazon.com/ecr/pricing/)
- [Amazon ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [AWS CodeArtifact Pricing](https://aws.amazon.com/codeartifact/pricing/)
- [GCP Artifact Registry Overview](https://cloud.google.com/artifact-registry/docs/overview)
- [GCP Artifact Registry Pricing](https://cloud.google.com/artifact-registry/pricing)
- [Azure Container Registry SKUs](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus)
- [Azure Container Registry Pricing](https://azure.microsoft.com/en-us/pricing/details/container-registry/)

**Serverless Platforms:**
- [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [AWS Lambda Developer Guide — Limits](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
- [Lambda SnapStart](https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html)
- [GCP Cloud Run Pricing](https://cloud.google.com/run/pricing)
- [GCP Cloud Run Quotas](https://cloud.google.com/run/quotas)
- [Azure Functions Scale and Hosting](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale)
- [Azure Functions Pricing](https://azure.microsoft.com/en-us/pricing/details/functions/)
- [Azure Durable Functions Overview](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview)
