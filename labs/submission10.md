# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Services Overview

**AWS:**
- **Amazon Elastic Container Registry (ECR):** Private Docker/OCI registry with vulnerability scanning (Amazon Inspector), encryption at rest, IAM integration, cross-region/account replication, and CI/CD hooks.
- **AWS CodeArtifact:** Managed package repository for Maven, npm, PyPI, NuGet, and Cargo. Integrates with standard package managers and AWS build tools.

**Google Cloud:**
- **Artifact Registry:** Unified registry for container images and language packages (Maven, npm, Python, Go, etc.). Includes IAM, vulnerability scanning, attestations, and Cloud Build integration.

**Azure:**
- **Azure Container Registry (ACR):** Private Docker/OCI registry with geo-replication (Premium tier), content trust/signing, Private Link, and ACR Tasks.
- **Azure Artifacts:** Azure DevOps service for language packages (npm, Maven, NuGet, Python, Cargo, Universal Packages).

### Supported Artifact Types

| Cloud | Service | Containers | Helm | Maven | npm | Python | NuGet | Go | OS Packages | Generic |
|-------|---------|-----------|------|-------|-----|--------|-------|----|-------------|---------|
| AWS | ECR | ✅ | ✅ (OCI) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (OCI) |
| AWS | CodeArtifact | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ (Cargo) | ❌ | ❌ |
| GCP | Artifact Registry | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ (apt/yum) | ✅ |
| Azure | ACR | ✅ | ✅ (OCI) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Azure | Azure Artifacts | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ (Cargo) | ❌ | ✅ (Universal) |

### Key Features

**Security & Compliance:**
- **ECR:** Image scanning via Inspector, KMS/SSE encryption, IAM policies
- **Artifact Registry:** Vulnerability scanning and attestations, IAM
- **ACR:** Image signing/content trust, Defender integrations, private networking

**Networking & Replication:**
- **ECR:** Cross-region and cross-account replication, VPC endpoints
- **Artifact Registry:** Regional repositories, Private Service Connect
- **ACR:** Geo-replication (Premium tier), Private Link

**CI/CD & Ecosystem:**
- **ECR:** Tight integration with ECS/EKS/CodeBuild/CodePipeline
- **Artifact Registry:** Cloud Build, Cloud Deploy, GKE
- **ACR:** AKS, GitHub Actions/Azure Pipelines, ACR Tasks (builds, base-image updates)

### Comparison Table

| Factor | AWS ECR | GCP Artifact Registry | Azure ACR |
|--------|---------|----------------------|-----------|
| Artifact formats | Docker/OCI | Docker/OCI + Maven/npm/Python/Go/OS packages | Docker/OCI |
| Vulnerability scanning | ✅ (Inspector) | ✅ (Artifact Analysis) | ✅ (Defender/partner) |
| Replication | Cross-region/account | Regional repos | Geo-replication (Premium) |
| Access control | IAM | IAM | RBAC/AAD |
| Private networking | VPC endpoints | Private Service Connect | Private Link |
| CI/CD integration | ECS/EKS/Code* | Cloud Build/Deploy/GKE | AKS/ACR Tasks/Pipelines |
| Pricing | Storage + egress | Storage + egress | SKU tier + features |

### Analysis: Multi-Cloud Strategy

For a multi-cloud setup, **GCP Artifact Registry** is the most unified option — it covers containers, language packages, and OS packages in one service. If you need everything in one place, it's hard to beat.

For **AWS-centric stacks**, pair **ECR** (images) with **CodeArtifact** (packages) for full coverage and deep AWS integration.

For **Azure-centric stacks** that need geo-replication and private networking, **ACR Premium** makes sense.

**Bottom line:** Choose based on your platform preference and network/replication needs. Keep artifacts OCI-compliant and policies portable to avoid lock-in.

---

## Task 2 — Serverless Computing Platform Research

### Services Overview

**AWS:**
- **Lambda:** Functions-as-a-Service (FaaS) with rich event ecosystem (S3, SNS, EventBridge, API Gateway). Max runtime **15 minutes**. Cold start mitigation: Provisioned Concurrency, SnapStart (Java).

**Google Cloud:**
- **Cloud Functions (Gen2) / Cloud Run:** Functions on Cloud Run or direct serverless containers with HTTP/event triggers. Cloud Run allows per-request runtimes up to **60 minutes** and supports minimum instances to keep containers warm.

**Azure:**
- **Azure Functions:** FaaS with multiple hosting plans. **Consumption** has default timeout up to **10 minutes**; **Premium** reduces cold starts via pre-warmed instances and allows longer runtimes with VNet integration.

### Runtimes and Execution Models

**Lambda:** Multiple managed runtimes (Node.js, Python, Java, .NET, Ruby, Go) or custom container images. Automatic scaling, concurrency controls, wide event sources.

**Cloud Functions/Run:** HTTP and event triggers, Pub/Sub, Eventarc. Min/max instances for scale and cold-start control. Supports Node.js, Python, Go, Java, .NET, PHP, Ruby.

**Azure Functions:** HTTP/queue/timer/event triggers. Premium keeps instances pre-warmed. Deep Azure integrations. Supports JavaScript/TypeScript, C#/F#, Python, Java, PowerShell, custom handlers.

### Performance Characteristics

**Cold starts:**
- Lambda: Provisioned Concurrency and SnapStart reduce startup latency
- Cloud Run: Min instances keep containers hot
- Azure Functions Premium: Pre-warmed workers

**Throughput & concurrency:** All three provide automatic scaling with per-platform concurrency and quota controls.

**Observability:** CloudWatch (AWS), Cloud Logging/Trace (GCP), Application Insights (Azure).

### Limits and Timeouts

| Platform | Max Duration | Cold-Start Mitigation |
|----------|--------------|----------------------|
| AWS Lambda | 15 minutes | Provisioned Concurrency, SnapStart (Java) |
| GCP Cloud Run | 60 minutes | Min instances |
| GCP Cloud Functions (Gen2) | Inherits Cloud Run (60 min) | Min instances |
| Azure Functions | 10 min (Consumption), longer on Premium | Pre-warmed instances (Premium) |

### Comparison Table

| Factor | AWS Lambda | GCP Cloud Functions / Cloud Run | Azure Functions |
|--------|------------|--------------------------------|-----------------|
| Model | FaaS | FaaS / serverless containers | FaaS |
| Max duration | 15 min | 60 min (Cloud Run HTTP) | 10 min (Consumption), longer in Premium |
| Cold start mitigation | Provisioned Concurrency, SnapStart | Min instances (Cloud Run) | Pre-warmed instances (Premium) |
| Triggers | Broad AWS events + HTTP | HTTP, Pub/Sub, Eventarc | HTTP, Timer, Queues, Event Hub |
| Networking | VPC integration | VPC/serverless VPC access | VNet integration |
| Pricing | Requests + GB-s + optional provisioned | Requests + time/CPU/mem | Requests + time; Premium warm cost |

### Analysis: Best Fit for REST API Backend

For **low latency, AWS-native** setups: **Lambda with Provisioned Concurrency** provides predictable startup at extra cost.

For **containerized HTTP with more control**: **Cloud Run** offers standard containers, long HTTP timeouts (60 min), and min instances to keep things warm. Best choice if you want flexibility.

For **Azure-native with stable latency**: **Functions on Premium plan** for pre-warmed workers and VNet integration.

I'd lean toward **Cloud Run** for a REST API — it accepts standard containers or functions, allows high concurrency per instance, has the longest HTTP timeout, and lets you keep a warm instance running to smooth out latency.

### Reflection: Pros & Cons of Serverless

**Pros:**
- No server management
- Automatic scaling
- Pay-for-use
- Scale-to-zero

**Cons:**
- Cold starts can cause delays
- Per-platform limits and quotas
- Requires tuning for latency
- Possible vendor lock-in with proprietary triggers and monitoring

The trade-off is clear: you get operational simplicity and cost efficiency, but you lose some control and have to work around platform-specific limitations.
