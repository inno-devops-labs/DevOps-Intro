# Lab 10 — Cloud Computing Fundamentals

---

## Task 1 — Artifact Registries Research

An artifact registry is a managed service for storing, versioning, and distributing build outputs — container images, language packages (npm, Maven, PyPI), and binary assets. All three major providers offer managed solutions deeply integrated with their own ecosystems.

---

### AWS — Elastic Container Registry (ECR) + CodeArtifact

**Container registry:** Amazon ECR  
**Package registry:** AWS CodeArtifact  
Docs: https://docs.aws.amazon.com/ecr/ | https://docs.aws.amazon.com/codeartifact/

ECR is AWS's managed Docker/OCI registry. It comes in two flavors: ECR Private (access controlled via IAM, for internal images) and ECR Public (for publicly distributable images via gallery.ecr.aws).

**Key features:**
- Native IAM integration — access policies work exactly like S3 bucket policies, familiar to anyone already on AWS
- Enhanced scanning via Amazon Inspector (powered by Snyk CVE data) plus basic scanning using Clair
- Immutable image tags — prevent overwriting a tagged image, enforces immutability in prod
- Cross-region and cross-account replication via replication rules
- Lifecycle policies — expire old/untagged images automatically to control storage costs
- Pull-through cache — proxy Docker Hub, ECR Public, Quay into a private ECR registry (useful for air-gapped environments)

CodeArtifact handles non-container packages: npm, PyPI, Maven, Gradle, NuGet, SwiftPM, generic formats. It acts as a proxy and cache for public registries — packages are downloaded from npmjs.com/PyPI on first request and cached, so subsequent pulls work even if upstream is down.

**Pricing (ECR):** $0.10/GB/month storage. No charge for data transfer between ECR and ECS/EKS in the same region. Enhanced scanning: $0.09/image.

---

### GCP — Artifact Registry

**Service:** Google Artifact Registry  
Docs: https://cloud.google.com/artifact-registry/docs

Artifact Registry (AR) replaced the older Container Registry (GCR) as Google's unified artifact platform in 2021. GCR still works but is deprecated for new projects.

The main differentiator is that AR is genuinely unified — one service handles Docker/OCI images, Maven, npm, Python, Apt, Yum/RPM, Go modules, Helm charts, and generic binaries. With AWS you need ECR + CodeArtifact as separate services; with GCP it's one thing.

**Key features:**
- Multi-format single service — containers and packages under one IAM policy, one billing line, one API
- Regional and multi-regional repos — choose storage location for data residency compliance
- Vulnerability scanning via Container Analysis (Google's own CVE data + Grafeas); integrates with Binary Authorization to block deployments with unfixed critical CVEs
- VPC Service Controls — restrict registry access to specific VPC networks
- CMEK support for compliance requirements
- Remote repositories — proxy and cache Docker Hub, npm, PyPI, Maven Central (equivalent to ECR pull-through cache)
- Virtual repositories — aggregate multiple upstreams behind one URL
- Deep integration with Cloud Build, Cloud Run, GKE, Cloud Deploy

**Pricing:** $0.10/GB/month. Data transfer free within same region. First 500GB storage free per month.

---

### Azure — Azure Container Registry (ACR) + Azure Artifacts

**Container registry:** Azure Container Registry  
**Package registry:** Azure Artifacts (part of Azure DevOps)  
Docs: https://docs.microsoft.com/azure/container-registry/

ACR has three tiers with meaningfully different capabilities:
- **Basic** — 10GB, no geo-replication, no private link
- **Standard** — 100GB, webhooks
- **Premium** — 500GB, geo-replication, private link, customer-managed keys, dedicated data endpoints

**Key features:**
- Geo-replication (Premium) — replicate to multiple Azure regions; reads go to nearest replica
- Microsoft Defender for Containers integration for vulnerability scanning
- ACR Tasks — cloud-based container build service; triggers on git commit, base image update, or schedule
- Private Link / Private Endpoint — restrict registry to specific VNets
- OCI artifact support via ORAS — store Helm charts, SBOMs, attestations alongside images
- Easy AKS integration — attach ACR to AKS with one `az aks update` command

Azure Artifacts supports npm, NuGet, Maven, Python, Cargo (Rust), Universal Packages. 2GB free per organization.

**Pricing (Premium):** ~$0.10/GB/month. Geo-replication: ~$1.67/day per additional region.

---

### Comparison Table

| Feature | AWS ECR + CodeArtifact | GCP Artifact Registry | Azure ACR + Artifacts |
|---|---|---|---|
| Container formats | Docker, OCI | Docker, OCI, Helm | Docker, OCI, Helm (ORAS) |
| Package formats | npm, PyPI, Maven, NuGet, SwiftPM | npm, PyPI, Maven, Apt, Yum, Go, Helm | npm, NuGet, Maven, PyPI, Cargo |
| Unified service | No (2 separate services) | Yes | Partial (ACR + Artifacts separate) |
| Vulnerability scanning | Amazon Inspector | Container Analysis | Defender for Containers |
| Geo-replication | Yes | Yes (multi-regional repos) | Yes (Premium only) |
| Public registry caching | Pull-through cache | Remote repositories | Upstream sources |
| Private networking | VPC endpoint | VPC Service Controls | Private Link |
| CI/CD integration | CodePipeline, CodeBuild | Cloud Build, Cloud Deploy | Azure Pipelines, GitHub Actions |
| Free tier | 500MB/month (ECR private) | 500MB/month | 2GB (Artifacts) |
| Storage pricing | $0.10/GB/month | $0.10/GB/month | ~$0.10/GB/month |

---

### Analysis — Multi-Cloud Registry Choice

For a multi-cloud strategy I'd choose **GCP Artifact Registry** as the primary hub.

The main reason is the unified multi-format support. AR handles containers, npm, PyPI, Maven, Helm, Apt, and generic binaries all in one service under one IAM model. With AWS you're managing two separate services (ECR + CodeArtifact) with different APIs, different billing, and different access control paradigms. That adds complexity that doesn't pay off unless you're deeply invested in AWS-specific features.

AR's remote repository feature is also genuinely useful for multi-cloud — it proxies and caches packages from Docker Hub, npm, PyPI, and Maven Central, meaning all your build systems (regardless of which cloud they're on) pull from a local cached copy. Consistent, fast, compliant.

That said, in a real multi-cloud setup you'd typically use each provider's native registry for workloads deployed to that cloud (ECR for EKS, ACR for AKS) to avoid cross-cloud egress costs. A neutral option like JFrog Artifactory or GitHub Packages as the canonical source of truth that pushes to cloud-specific registries is worth considering for large orgs. But if forced to pick one cloud-native service for everything, AR wins on breadth.

---

## Task 2 — Serverless Computing Platform Research

Serverless computing lets you deploy functions that run on-demand without managing any servers. The provider handles scaling, availability, and infrastructure — you pay only for actual execution time.

---

### AWS — Lambda

**Primary FaaS:** AWS Lambda  
**Serverless containers:** AWS Fargate  
Docs: https://docs.aws.amazon.com/lambda/

Lambda is the most mature serverless platform. It's been available since 2014 and has the deepest ecosystem integration of any provider.

**Runtimes:** Node.js 18/20, Python 3.10–3.12, Java 8/11/17/21, .NET 6/8, Ruby 3.2, Go (via `provided.al2023`), custom runtimes via Layers

**Triggers:** API Gateway, ALB, S3 events, DynamoDB Streams, Kinesis, SNS, SQS, EventBridge, Cognito, CloudFront (Lambda@Edge), 200+ other AWS services

**Key specs:**
- Max execution: 15 minutes
- Memory: 128MB–10GB; CPU scales proportionally
- Concurrency: 1,000 concurrent executions per region (soft limit)
- Cold start: ~50–200ms Node.js/Python; ~500ms–2s JVM; SnapStart available for JVM (checkpoint restore, eliminates most cold start time)

**Lambda@Edge:** Run functions at CloudFront PoPs globally. Sub-1ms execution for simple transformations like A/B testing, header manipulation, URL rewrites.

**Pricing:** Free tier: 1M requests + 400K GB-seconds/month. After: $0.20/1M requests + $0.0000166667/GB-second.

---

### GCP — Cloud Functions (Gen 2) + Cloud Run

**Primary FaaS:** Cloud Functions Gen 2  
**Serverless containers:** Cloud Run  
Docs: https://cloud.google.com/functions/docs | https://cloud.google.com/run/docs

Cloud Functions Gen 2 is built on Cloud Run under the hood. The main differences from Lambda: 60-minute max execution (vs Lambda's 15), up to 1,000 concurrent requests per instance (vs Lambda's 1), and up to 32GB memory.

**Runtimes:** Node.js 16/18/20, Python 3.8–3.12, Go 1.16–1.21, Java 11/17/21, Ruby 3.0/3.2, PHP 8.1/8.2, .NET 6/8

The concurrency model is the biggest architectural difference: Cloud Functions/Run allows a single instance to handle 1,000 concurrent requests. Lambda is strictly 1 request per instance. For a high-traffic API this means Cloud Run can absorb burst traffic with far fewer cold starts because existing instances aren't idle — one instance handles many parallel requests.

**Cloud Run** is Cloud Functions without the language restrictions — any containerized workload. Cloud Run Jobs handles batch/one-off workloads.

**Pricing:** Free tier: 2M requests + 400K GB-seconds/month. After: $0.40/1M requests + $0.00002400/vCPU-second.

---

### Azure — Azure Functions + Container Apps

**Primary FaaS:** Azure Functions  
**Serverless containers:** Azure Container Apps  
Docs: https://docs.microsoft.com/azure/azure-functions/

Azure Functions has three hosting plans with very different characteristics:
- **Consumption** — true serverless, pay-per-execution, scale to 0, 10-min max execution, cold starts 1–3s
- **Premium** — pre-warmed instances eliminate cold starts, VNet integration, unlimited execution duration
- **Dedicated** — App Service Plan, always-on

**Runtimes:** C# (.NET 6/7/8), JavaScript/TypeScript (Node.js 18/20), Python 3.8–3.11, Java 8/11/17/21, PowerShell 7.2, custom handlers (Go, Rust)

**Durable Functions** is a standout feature: stateful orchestration using actor/saga patterns with checkpointed state in Azure Storage. Useful for workflows that span multiple function invocations. Nothing directly equivalent exists in Lambda or Cloud Functions natively.

Cold starts on Consumption plan are noticeably worse than AWS or GCP: 1–3 seconds vs Lambda's 50–200ms. Premium plan fixes this but adds cost.

**Azure Container Apps:** Serverless container hosting built on Kubernetes + KEDA. Event-driven scaling, Dapr integration for microservice patterns, revision-based traffic splitting. Sits between pure FaaS and full AKS.

**Pricing (Consumption):** Free tier: 1M requests + 400K GB-seconds/month. After: $0.20/1M requests + $0.000016/GB-second.

---

### Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions Gen 2 / Cloud Run | Azure Functions |
|---|---|---|---|
| Max execution | 15 min | 60 min | 10 min (Consumption) / unlimited (Premium) |
| Memory limit | 10 GB | 32 GB | 14 GB (Premium) |
| Concurrency per instance | 1 request | Up to 1,000 requests | Configurable |
| Cold start (Node.js) | ~50–200ms | ~100–500ms | ~1,000–3,000ms |
| Cold start mitigation | Provisioned concurrency, SnapStart | Min instances | Premium plan |
| Languages | Node, Python, Java, .NET, Ruby, Go, custom | Node, Python, Go, Java, .NET, Ruby, PHP | C#, Node, Python, Java, PowerShell, Go, Rust |
| Stateful orchestration | Step Functions (separate service) | Workflows (separate service) | Durable Functions (built-in) |
| Edge execution | Lambda@Edge, CloudFront Functions | — | — |
| Free tier requests | 1M/month | 2M/month | 1M/month |
| Price per 1M requests | $0.20 | $0.40 | $0.20 |

---

### Analysis — Serverless for a REST API Backend

For a REST API I'd go with **AWS Lambda + API Gateway**.

Lambda's cold start performance (50–200ms for Node.js/Python) is the best of the three out of the box, and provisioned concurrency eliminates cold starts entirely for latency-sensitive paths. API Gateway v2 (HTTP API) adds sub-millisecond routing overhead with built-in JWT authorizers and CORS — the complete API infrastructure is just Lambda + API Gateway, no other moving parts.

**GCP Cloud Run is a strong alternative** for high-traffic APIs specifically. The per-instance concurrency model (1,000 concurrent requests per container) means existing instances absorb burst traffic rather than spawning new ones. Fewer cold starts under load. The 60-minute execution limit is useful too if the API needs to support long-polling or streaming. If the team prefers containerized deployments over zip archives, Cloud Run wins.

**Azure Functions Consumption** I'd avoid for a latency-sensitive API — 1–3 second cold starts on the Consumption plan are hard to explain to users. Premium plan fixes it but at that point you're paying for always-on capacity which undercuts the serverless value proposition.

---

### Reflection — Serverless Advantages and Disadvantages

**Advantages:**

Zero infrastructure management — no patching, capacity planning, or availability engineering for the compute layer. The provider handles all of that. Auto-scaling is automatic, including scaling to zero (no idle cost). Development focus shifts to application logic rather than operations. High availability across multiple zones is the default.

**Disadvantages:**

Cold starts are the most operationally painful aspect. The first request after idle (50ms for Lambda, up to 3s for Azure Functions Consumption) is noticeably slower than subsequent ones. For user-facing APIs this matters. Solutions exist (provisioned concurrency, min instances) but they add cost and partly undermine the "pay only for what you use" model.

Execution duration limits (Lambda 15min, Azure Consumption 10min) prevent serverless from being a universal compute solution. Anything that runs longer — batch jobs, video processing, long-running ML inference — needs a different approach.

Vendor lock-in is real. The function code itself is portable, but the trigger configurations, IAM roles, environment variable management, and service integrations are all provider-specific. Migrating between providers requires significant rework of everything except the actual business logic.

Observability is harder than with monoliths. Distributed traces across hundreds of short-lived invocations require investment in tools like X-Ray, Cloud Trace, or Application Insights. Debugging is less intuitive when you can't reproduce the exact execution environment locally.

The bottom line: serverless is the right default for event-driven workloads, lightweight APIs, scheduled tasks, and glue code between services. It's the wrong choice for long-running, stateful, or consistently high-traffic workloads where the cold start overhead and external state requirements outweigh the operational savings.

---

## Sources

- AWS ECR: https://docs.aws.amazon.com/ecr/latest/userguide/
- AWS CodeArtifact: https://docs.aws.amazon.com/codeartifact/latest/ug/
- AWS Lambda: https://docs.aws.amazon.com/lambda/latest/dg/
- GCP Artifact Registry: https://cloud.google.com/artifact-registry/docs
- GCP Cloud Functions: https://cloud.google.com/functions/docs
- GCP Cloud Run: https://cloud.google.com/run/docs
- Azure Container Registry: https://docs.microsoft.com/azure/container-registry/
- Azure Artifacts: https://docs.microsoft.com/azure/devops/artifacts/
- Azure Functions: https://docs.microsoft.com/azure/azure-functions/
- Azure Container Apps: https://docs.microsoft.com/azure/container-apps/
