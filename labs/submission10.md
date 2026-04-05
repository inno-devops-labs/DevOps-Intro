# Lab 10 — Cloud Computing Fundamentals: Artifact Registries & Serverless Platforms

**Student:** Diana Minnakhmetova  
**Date:** 5 April 2025


---

## Task 1 — Artifact Registries Research

### Overview

Artifact registries are centralized services for storing, versioning, and distributing build
artifacts — container images, packages (npm, Maven, PyPI), Helm charts, and more.
They are a cornerstone of modern CI/CD pipelines, enabling teams to manage dependencies,
enforce security policies, and deliver software consistently across environments.

---

### 1.1 AWS — Amazon Elastic Container Registry (ECR)

**Official Name:** Amazon Elastic Container Registry (ECR)  
**Docs:** https://docs.aws.amazon.com/ecr/

**Key Features:**
- Stores Docker/OCI container images and Helm charts
- Built-in **vulnerability scanning** via Amazon Inspector (on-push and continuous modes)
- **Private and public repositories** (ECR Public Gallery for open-source images)
- Fine-grained access control via **AWS IAM** — no separate user management required
- **Cross-region and cross-account replication** for geo-distribution
- **Lifecycle policies** to automatically clean up old or unused images
- **Immutable image tags** to prevent accidental overwrites
- **Pull-through cache** — proxy and cache images from upstream public registries (Docker Hub, GCR, etc.)
- Integrated natively with ECS, EKS, Lambda, CodePipeline, and CodeBuild

**Supported Artifact Types:**
- Docker / OCI container images
- Helm charts (OCI-compliant)

For language packages (npm, Maven, PyPI): AWS uses **CodeArtifact** as a separate service.

**Pricing Model:**
- **Storage:** ~$0.10/GB per month
- **Data transfer:** free within the same AWS Region; standard egress rates apply cross-region
- **Free tier:** 500 MB/month for private repositories (first 12 months); ECR Public is free for public images

**Common Use Cases:**
- Storing and distributing container images in AWS-native deployment pipelines (ECS, EKS)
- Secure enterprise container supply chains with IAM-enforced access policies
- Pull-through caching to reduce Docker Hub rate-limit issues in large teams

---

### 1.2 GCP — Google Artifact Registry (GAR)

**Official Name:** Google Artifact Registry (GAR)  
**Docs:** https://cloud.google.com/artifact-registry/docs

⚠️ **Important:** Google Container Registry (GCR) was deprecated in 2023 and is scheduled
for shutdown in 2025. **Google Artifact Registry is the official successor** and the
recommended service for all new and existing workloads on GCP.

**Key Features:**
- **Multi-format registry**: Docker images, Maven, npm, Python (PyPI), Apt, Yum, Helm,
  and generic binary artifacts — all managed in a single service
- **Regional and multi-regional repositories** for geo-distribution and low-latency pulls
- Vulnerability scanning via **Artifact Analysis** (on-push and continuous)
- **IAM-based access control** integrated with Google Cloud identity
- **Virtual repositories** — aggregate multiple upstream registries behind a single endpoint
- **Remote repositories** — proxy and cache external public registries (Docker Hub, Maven Central,
  PyPI), reducing egress costs and eliminating rate-limit failures
- **CMEK** (Customer-Managed Encryption Keys) support for compliance requirements
- Integrated with Cloud Build, GKE, Cloud Run, Cloud Deploy, and Cloud Functions

**Supported Artifact Types:**
- Docker / OCI container images
- Maven (Java)
- npm (Node.js)
- Python (PyPI)
- Apt / Yum (Linux packages)
- Helm charts
- Generic binary artifacts

**Pricing Model:**
- **Storage:** ~$0.10/GB per month
- **Network egress:** free within the same region; standard GCP rates apply cross-region
- **Free tier:** 0.5 GB/month free storage

**Common Use Cases:**
- Unified artifact management across multiple languages and formats on GCP
- Pull-through caching for Docker Hub and Maven Central to improve CI reliability
- Centralized package management for polyglot microservices teams

---

### 1.3 Azure — Azure Container Registry (ACR)

**Official Name:** Azure Container Registry (ACR)  
**Docs:** https://learn.microsoft.com/azure/container-registry/

**Note:** ACR focuses on container images and OCI artifacts. For language packages
(npm, NuGet, Maven), Azure uses **Azure Artifacts** (part of Azure DevOps) as a
separate service — an important distinction that is often overlooked.

**Key Features:**
- Docker/OCI container image storage
- **Geo-replication** (Premium tier) — replicate a single registry to multiple Azure regions
  with a unified endpoint, reducing latency for distributed teams
- Vulnerability scanning via **Microsoft Defender for Containers**
- **ACR Tasks** — built-in CI/CD capability: automatically rebuild images on git commits
  or base image updates, without external pipeline tooling
- **Webhooks** for triggering downstream CI/CD pipelines on image push events
- **Content Trust** (Docker Notary v2) for image signing and verification
- **Private Endpoints** via Azure Private Link for network-isolated deployments
- RBAC via **Azure Active Directory**
- **Connected Registry** — extend ACR to offline or edge environments
  (unique feature not available in ECR or GAR)
- Integrated with AKS, Azure Container Apps, App Service, and Azure DevOps

**Supported Artifact Types:**
- Docker / OCI container images
- Helm charts
- OCI Artifacts (general-purpose)

**Pricing Model (tiers):**

| Tier | Included Storage | Daily Rate | Monthly Equivalent |
|------|-----------------|------------|-------------------|
| Basic | 10 GB | ~$0.167/day | ~$5/month |
| Standard | 100 GB | ~$0.667/day | ~$20/month |
| Premium | 500 GB + geo-replication | ~$1.667/day | ~$50/month |

- Data transfer within the same Azure region is free; standard egress rates apply otherwise
- Geo-replication billed per additional replicated region (Premium only)

**Common Use Cases:**
- Containerized workloads on AKS and Azure Container Apps
- Enterprise geo-distributed deployments requiring a single registry endpoint (Premium)
- Edge and offline container distribution via Connected Registry

---

### 1.4 Comparison Table — Artifact Registries

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---|---|---|---|
| **Service Name** | Amazon ECR | Google Artifact Registry | Azure Container Registry |
| **Container Images** | ✅ | ✅ | ✅ |
| **Helm Charts** | ✅ (OCI) | ✅ | ✅ |
| **Language Packages** | ❌ (CodeArtifact) | ✅ npm, Maven, PyPI, Apt… | ❌ (Azure Artifacts) |
| **Vulnerability Scanning** | ✅ Amazon Inspector | ✅ Artifact Analysis | ✅ Microsoft Defender |
| **Geo-Replication** | ✅ cross-region | ✅ multi-region repos | ✅ Premium tier only |
| **Access Control** | AWS IAM | Google Cloud IAM | Azure AD / RBAC |
| **Pull-through Cache** | ✅ upstream proxies | ✅ Remote repositories | ✅ Cache rules |
| **CI/CD Integration** | CodePipeline, GitHub Actions | Cloud Build, GitHub Actions | ACR Tasks, Azure DevOps |
| **Immutable Tags** | ✅ | ✅ | ✅ |
| **Pricing (storage)** | ~$0.10/GB | ~$0.10/GB | ~$5/month (Basic), ~$20/month (Standard), ~$50/month (Premium) |
| **Free Tier** | 500 MB/month | 0.5 GB/month | None (pay-per-use) |
| **Edge / Offline Support** | ❌ | ❌ | ✅ Connected Registry |
| **Multi-format (non-container)** | ❌ | ✅ | ❌ |

---

### 1.5 Analysis: Registry Choice for a Multi-Cloud Strategy

**Recommended primary registry: Google Artifact Registry (GAR)**  
**Secondary for Azure-native workloads: Azure Container Registry (ACR)**

**Reasoning:**

**1. Format breadth is the decisive factor in multi-cloud.**
GAR is the only service among the three that natively handles container images *and* language
packages (npm, Maven, PyPI, Apt) within a single product. In a multi-cloud environment,
eliminating the need for separate services (CodeArtifact on AWS, Azure Artifacts on Azure)
reduces operational complexity and unifies the artifact management toolchain.

**2. Remote/virtual repositories solve real operational problems.**
GAR's ability to proxy and cache upstream public registries (Docker Hub, Maven Central)
eliminates Docker Hub rate-limit failures in CI pipelines and reduces cross-region egress costs.
This is a concrete operational advantage, not a marketing differentiator.

**3. Standard protocols reduce vendor lock-in.**
GAR uses standard OCI/Docker protocols, which means pulling images from it in AWS or Azure
environments requires no special tooling — just `docker pull` with standard auth. This is
the correct default for a multi-cloud strategy where portability matters.

**4. Trade-offs acknowledged:**
- If the team is 100% committed to AWS with ECS/EKS, ECR's IAM-native integration and
  tighter service coupling make it the pragmatic choice.
- If geo-replicated enterprise deployments with a single endpoint are the priority and the
  team runs on Azure, ACR Premium is compelling.
- GAR is the best default for new, multi-cloud, or polyglot projects.

---

## Task 2 — Serverless Computing Platform Research

### Overview

Serverless computing is an execution model where the cloud provider dynamically allocates
resources to run code in response to events or HTTP requests. The provider manages
provisioning, scaling, and infrastructure — developers focus solely on business logic.
The key value proposition: pay only for actual execution time, not idle capacity.

---

### 2.1 AWS — AWS Lambda

**Official Name:** AWS Lambda  
**Docs:** https://docs.aws.amazon.com/lambda/

**Key Features:**
- Event-driven execution triggered by 200+ AWS services (S3, DynamoDB, API Gateway,
  SQS, SNS, EventBridge, Kinesis, and more)
- **Lambda Layers** — share code, libraries, and configurations across multiple functions
- **Lambda Extensions** — integrate third-party monitoring, security, and observability tools
- **Provisioned Concurrency** — pre-initializes execution environments to eliminate cold starts
  for latency-sensitive workloads
- **SnapStart** (Java runtime) — snapshot and restore pre-initialized environments to
  dramatically reduce Java cold starts
- **Lambda@Edge / CloudFront Functions** — run code at CDN edge locations globally
- **Container image support** — package functions as Docker images up to 10 GB
- **Lambda Function URLs** — built-in HTTPS endpoints without API Gateway
- Memory: 128 MB to 10 GB; vCPU scales proportionally with memory allocation

**Supported Runtimes:**
Node.js, Python, Java, C# (.NET), Go, Ruby, PowerShell, custom runtimes via provided.al2

**Execution Models:**
- Synchronous (HTTP via API Gateway, ALB, Function URLs)
- Asynchronous (S3 events, SNS, EventBridge)
- Stream-based (DynamoDB Streams, Kinesis)

**Pricing:**
- **Requests:** $0.20 per 1M requests
- **Duration:** $0.0000166667 per GB-second (billed in 1ms increments)
- **Free tier:** 1M requests + 400,000 GB-seconds/month (permanent, not time-limited)

**Cold Start Characteristics:**
- Typically 100ms–1s depending on runtime (Python/Node.js fastest; Java slowest without SnapStart)
- Provisioned Concurrency eliminates cold starts for pre-warmed environments
- SnapStart reduces Java cold starts by up to 90%

**Observability & Monitoring:**
- **Amazon CloudWatch** — built-in metrics (invocations, duration, errors, throttles),
  logs, and alarms; no additional configuration required
- **AWS X-Ray** — distributed tracing for end-to-end request visibility across Lambda
  and downstream services (DynamoDB, API Gateway, SQS)
- **Lambda Insights** (CloudWatch extension) — enhanced runtime metrics including
  memory usage, CPU, and init duration

**Max Execution Duration:** 15 minutes

---

### 2.2 GCP — Google Cloud Functions + Cloud Run

**Official Names:**
- **Google Cloud Functions (Gen 2)** — https://cloud.google.com/functions
- **Google Cloud Run** — https://cloud.google.com/run

GCP's serverless compute story is intentionally split across two complementary services.
**Cloud Functions** targets simple, event-driven function-level workloads.
**Cloud Run** targets containerized applications with more control over the runtime.
Together they cover the full serverless spectrum — this is how GCP officially positions them.

**Google Cloud Functions (Gen 2):**
- Gen 2 is built on top of Cloud Run infrastructure, inheriting its scaling capabilities
- Event sources: Cloud Storage, Pub/Sub, Firestore, BigQuery, HTTP triggers, Eventarc (100+ event types)
- Memory: up to 16 GB; vCPU: up to 4
- Max execution duration: **60 minutes**

**Google Cloud Run:**
- Deploy any containerized application as a serverless workload — no function size constraints
- Scales to zero automatically; scales to thousands of instances on demand
- **Min-instances** setting eliminates cold starts for production workloads
- **Concurrency per instance: up to 1,000 concurrent requests per container**
  (vs. Lambda's default of 1 per instance — a significant architectural difference for REST APIs)
- Supports **gRPC, WebSockets, HTTP/2, and HTTP/1.1**
- **Cloud Run Jobs** — run containerized batch workloads; max duration **24 hours**
- Max HTTP request timeout: **60 minutes**

**Supported Runtimes (Cloud Functions Gen 2):**
Node.js, Python, Go, Java, Ruby, PHP, .NET

**Pricing (Cloud Functions Gen 2):**
- **Invocations:** $0.40 per 1M (after free tier)
- **Compute:** $0.0000100/vCPU-second + $0.0000025/GB-second
- **Free tier:** 2M invocations/month + 400,000 GB-seconds/month

**Cold Start Characteristics:**
- Cloud Functions Gen 2: comparable to Lambda (~100ms–2s depending on runtime)
- Cloud Run: lower cold starts due to container reuse and min-instances support

**Observability & Monitoring:**
- **Cloud Logging** — automatic log ingestion from Cloud Functions and Cloud Run with
  structured log support; no SDK integration required
- **Cloud Monitoring** — built-in metrics dashboards for invocation count, latency,
  error rates, and instance count
- **Cloud Trace** — distributed tracing integrated with Cloud Run and Cloud Functions;
  compatible with OpenTelemetry for vendor-neutral instrumentation
- **Error Reporting** — automatic aggregation and alerting on unhandled exceptions

---

### 2.3 Azure — Azure Functions

**Official Name:** Azure Functions  
**Docs:** https://learn.microsoft.com/azure/azure-functions/

Azure also offers **Azure Container Apps** as a more flexible serverless container platform
(comparable to GCP Cloud Run) for teams that need more control over the runtime environment.

**Key Features:**
- **Durable Functions** — stateful, long-running orchestration workflows built on top of
  Azure Functions; supports fan-out/fan-in, human approval steps, and entity patterns.
  This is Azure's most significant serverless differentiator — not available natively in
  Lambda or Cloud Functions without external orchestration services (Step Functions, Workflows)
- Rich trigger and binding system: HTTP, Timer, Blob Storage, Queue Storage, Cosmos DB,
  Event Hub, Service Bus, SignalR, and more — declarative I/O bindings reduce boilerplate
- **Flex Consumption plan** (2024) — per-second billing with virtual network integration,
  addressing the long-standing limitation of the original Consumption plan
- **Premium plan** — pre-warmed instances eliminate cold starts; supports VNet integration
- **Always Ready instances** — guaranteed minimum instances for predictable latency
- **PowerShell support** — unique among the three providers, valuable for infrastructure
  automation and sysadmin workflows
- Deep integration with Azure DevOps, Visual Studio, and GitHub Actions
- **Custom handlers** — run any language runtime (Go, Rust, etc.) via HTTP-based protocol

**Supported Runtimes:**
C# (.NET), JavaScript/TypeScript, Python, Java, PowerShell, custom handlers (Go, Rust, etc.)

Ruby is **not** natively supported. PHP is available via custom handlers only.

**Execution Models:**
- HTTP-triggered, Timer-triggered, Event-driven (Queue/Blob/EventHub)
- **Durable Functions orchestration**: Orchestrator, Activity, Entity, and Sub-orchestration functions

**Pricing (Consumption Plan):**
- **Executions:** $0.20 per 1M
- **Execution time:** $0.000016 per GB-second (billed in 1ms increments)
- **Free grant:** 1M executions + 400,000 GB-seconds/month (permanent)

**Cold Start Characteristics:**
- Consumption plan has the highest cold starts among the three (~1–3s for .NET/Java)
- Premium plan with pre-warmed instances resolves this for production
- Flex Consumption plan (2024) significantly improves cold start behavior

**Observability & Monitoring:**
- **Azure Monitor** — platform-wide metrics collection for invocation count, duration,
  failures, and throttling; integrates with Log Analytics workspaces for advanced queries
- **Application Insights** — deep APM integration with distributed tracing, live metrics
  stream, dependency tracking, and failure analysis; first-class SDK support for all
  Azure Functions runtimes
- **Log Analytics** — centralized log querying via KQL (Kusto Query Language) across
  Functions, dependencies, and custom telemetry

**Max Execution Duration:**
- Consumption: 10 minutes default, configurable up to 60 minutes
- Premium / Dedicated: unlimited (no enforced timeout)
- Durable Functions: unlimited (orchestration can run for days)

---

### 2.4 Comparison Table — Serverless Platforms

| Feature | AWS Lambda | GCP Cloud Functions Gen 2 / Cloud Run | Azure Functions |
|---|---|---|---|
| **Launched** | 2014 | 2016 | 2016 |
| **Node.js** | ✅ | ✅ | ✅ |
| **Python** | ✅ | ✅ | ✅ |
| **Java** | ✅ | ✅ | ✅ |
| **C# / .NET** | ✅ | ✅ | ✅ |
| **Go** | ✅ | ✅ | ✅ (custom handler) |
| **Ruby** | ✅ | ✅ | ❌ |
| **PHP** | ❌ | ✅ | ✅ (custom handler) |
| **PowerShell** | ✅ | ❌ | ✅ |
| **Max Duration** | 15 min | 60 min (HTTP); 24h (Jobs) | 60 min (Consumption); unlimited (Premium) |
| **Max Memory** | 10 GB | 16 GB | 14 GB (Premium) |
| **Cold Start** | Low (100ms–1s) | Low–Medium | Medium–High (Consumption) |
| **Eliminate Cold Starts** | ✅ Provisioned Concurrency | ✅ Min-instances | ✅ Always Ready / Premium |
| **Container Image Support** | ✅ up to 10 GB | ✅ Cloud Run (any size) | ✅ |
| **Concurrency per Instance** | 1 (default) | 1,000 (Cloud Run) | 1 (Consumption) |
| **Stateful Orchestration** | ✅ Step Functions (separate) | ✅ Workflows (separate) | ✅ **Durable Functions (built-in)** |
| **Edge Computing** | ✅ Lambda@Edge | ✅ via Cloud CDN | ⚠️ Limited |
| **Metrics & Monitoring** | CloudWatch | Cloud Monitoring | Azure Monitor |
| **Distributed Tracing** | AWS X-Ray | Cloud Trace / OpenTelemetry | Application Insights |
| **Free Tier (requests/month)** | 1M | 2M | 1M |
| **Free Tier (compute/month)** | 400K GB-s | 400K GB-s | 400K GB-s |
| **Price per 1M requests** | $0.20 | $0.40 | $0.20 |
| **VNet Integration** | ✅ | ✅ | ✅ (Premium / Flex) |
| **WebSocket / gRPC** | ⚠️ Limited | ✅ Cloud Run | ⚠️ Limited |
| **Ecosystem Triggers** | 200+ AWS services | Eventarc (100+ sources) | 30+ Azure bindings |

---

### 2.5 Analysis: Best Choice for a REST API Backend

**Recommended: AWS Lambda + API Gateway**

**Primary reasoning:**

**1. Maturity and ecosystem depth.**
Lambda (2014) has the longest track record in production serverless deployments. The Lambda +
API Gateway combination is the most documented, most tooled, and most battle-tested pattern
for REST APIs in the industry. The ecosystem around it (Serverless Framework, AWS SAM, CDK,
Powertools for Lambda) is unmatched.

**2. Cold start performance for REST APIs.**
HTTP latency is a first-class concern for REST APIs. Lambda's cold starts are among the lowest
(especially for Python/Node.js runtimes at ~100ms), and Provisioned Concurrency can eliminate
them entirely for critical endpoints. This makes Lambda the most predictable choice for
user-facing APIs with strict SLA requirements.

**3. Competitive pricing.**
At $0.20/1M requests with a permanent free tier of 1M requests/month, Lambda is cost-competitive
for early-stage and high-scale APIs alike.

**4. Container image support.**
As the API grows in complexity, Lambda's 10 GB container image support allows packaging
complex dependency trees without Lambda Layer size constraints.

**When to choose alternatives:**

- **GCP Cloud Run** is arguably the strongest alternative specifically for REST APIs.
  Its 1,000 concurrent requests per container instance (vs. Lambda's 1) means fewer cold
  starts under sustained load, lower cost at scale, and better suitability for long-lived
  HTTP connections. If the team is already on GCP or building a containerized API,
  Cloud Run is a serious competitor — not a fallback.

- **Azure Functions** is the right choice if the team is invested in the Microsoft/Azure
  ecosystem, uses .NET or PowerShell runtimes, or needs Durable Functions for complex
  orchestration workflows within the same serverless context.

---

### 2.6 Reflection: Serverless Advantages & Disadvantages

#### Advantages

| Advantage | Description |
|---|---|
| **No infrastructure management** | The cloud provider handles provisioning, OS patching, scaling, and availability |
| **Automatic scaling** | Scales from zero to thousands of instances automatically; handles traffic spikes without pre-configuration |
| **Pay-per-use** | Billing is tied to actual execution time — idle time costs nothing, unlike always-on VMs |
| **Faster time-to-market** | Developers focus on business logic; operational overhead is dramatically reduced |
| **High availability by default** | Built-in fault tolerance and multi-AZ redundancy without additional configuration |
| **Event-driven architecture** | Natural fit for async processing, webhooks, data pipelines, and loosely coupled microservices |

#### Disadvantages

| Disadvantage | Description |
|---|---|
| **Cold starts** | First invocation after an idle period incurs latency (100ms to several seconds), problematic for latency-sensitive applications |
| **Execution duration limits** | Maximum timeouts (15–60 min) make serverless unsuitable for long-running computational workloads |
| **Vendor lock-in** | Deep integration with provider-specific triggers, bindings, and IAM systems makes cross-provider migration costly |
| **Debugging complexity** | Distributed, ephemeral, and stateless execution environments make local debugging, tracing, and reproducing issues harder |
| **State management overhead** | Functions are stateless by design — external state stores (Redis, DynamoDB, Cosmos DB) add architectural complexity |
| **Cost at sustained scale** | For consistently high-traffic workloads running 24/7, always-on servers (EC2, VMs) are often cheaper than pay-per-invocation billing |
| **Limited runtime control** | You cannot modify the underlying OS, kernel, or system libraries beyond what the provider exposes |

---

## Summary

| Category | AWS | GCP | Azure |
|---|---|---|---|
| **Artifact Registry** | Amazon ECR | Google Artifact Registry | Azure Container Registry |
| **Serverless Compute** | AWS Lambda | Cloud Functions Gen 2 / Cloud Run | Azure Functions |
| **Registry Differentiator** | IAM-native, ECR+ECS/EKS tight integration | Multi-format (npm, Maven, PyPI), remote repos | Geo-replication, ACR Tasks, Connected Registry (edge) |
| **Serverless Differentiator** | Broadest ecosystem, Lambda@Edge, SnapStart | Cloud Run concurrency (1000/instance), 24h Jobs | Durable Functions (stateful orchestration built-in) |
| **Best For (Registry)** | Pure AWS workloads | Multi-cloud / polyglot teams | Azure-native / geo-distributed enterprise |
| **Best For (Serverless)** | REST APIs, event pipelines, edge | Containerized APIs, high-concurrency workloads | Microsoft ecosystem, stateful workflows |

---

## References

| # | Source | URL |
|---|--------|-----|
| 1 | AWS ECR — Official Documentation | https://docs.aws.amazon.com/ecr/ |
| 2 | AWS Lambda — Official Documentation | https://docs.aws.amazon.com/lambda/ |
| 3 | AWS CodeArtifact — Official Documentation | https://docs.aws.amazon.com/codeartifact/ |
| 4 | Google Artifact Registry — Official Documentation | https://cloud.google.com/artifact-registry/docs |
| 5 | Google Cloud Functions Gen 2 — Official Documentation | https://cloud.google.com/functions/docs/concepts/version-comparison |
| 6 | Google Cloud Run — Official Documentation | https://cloud.google.com/run/docs |
| 7 | GCP Cloud Functions Pricing | https://cloud.google.com/functions/pricing |
| 8 | Azure Container Registry — Official Documentation | https://learn.microsoft.com/azure/container-registry/ |
| 9 | Azure Container Registry Pricing | https://azure.microsoft.com/pricing/details/container-registry/ |
| 10 | Azure Functions — Official Documentation | https://learn.microsoft.com/azure/azure-functions/ |
| 11 | Azure Functions Pricing | https://azure.microsoft.com/pricing/details/functions/ |
| 12 | Azure Durable Functions — Official Documentation | https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview |
| 13 | Google Cloud: AWS/Azure to GCP Service Mapping | https://cloud.google.com/docs/get-started/aws-azure-gcp-service-comparison |
| 14 | Shipyard: Choosing a Container Registry (2025) | https://shipyard.build/blog/container-registries/ |