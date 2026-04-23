# Lab 10 — Cloud Computing Fundamentals

---

## Task 1 — Artifact Registries Research

### Overview

An artifact registry is a managed repository service for storing, versioning, and distributing build artifacts — container images, language packages (npm, Maven, PyPI, etc.), and binary assets. All three major cloud providers offer managed registry services deeply integrated with their ecosystems.

---

### AWS — Elastic Container Registry (ECR) + CodeArtifact

**Primary container registry:** Amazon Elastic Container Registry (ECR)  
**Primary package registry:** AWS CodeArtifact  
**Documentation:** https://docs.aws.amazon.com/ecr/ | https://docs.aws.amazon.com/codeartifact/

#### ECR — Key Features
- Stores and distributes Docker/OCI container images
- **ECR Public Gallery** for public image hosting; **ECR Private** for internal use
- Native integration with ECS, EKS, Lambda, and CodePipeline — IAM policies control access at repository level
- **Enhanced scanning** powered by Amazon Inspector (uses Snyk for vulnerability data); basic scanning uses Clair
- **Immutable image tags** prevent tag overwriting — enforces image immutability in production
- **Replication** across AWS regions and accounts via replication rules
- **Lifecycle policies** automatically expire untagged or old images to control storage costs
- Pull-through cache allows caching images from Docker Hub, ECR Public, Quay into a private ECR registry

#### CodeArtifact — Key Features
- Supports **npm, PyPI, Maven, Gradle, NuGet, SwiftPM, generic** package formats
- Acts as a proxy and cache for public registries (npmjs.com, PyPI, Maven Central) — packages are cached on first pull
- Domain/repository hierarchy: one domain can contain many repositories across accounts
- Fine-grained IAM-based access control
- Upstream repository chaining — requests cascade through internal repos before hitting public upstreams

#### Pricing (ECR)
- Storage: $0.10/GB/month
- Data transfer out: standard AWS data transfer rates
- Enhanced scanning: $0.09 per image scan
- No charge for data transfer between ECR and ECS/EKS in same region

---

### GCP — Artifact Registry

**Primary service:** Google Artifact Registry (AR)  
**Documentation:** https://cloud.google.com/artifact-registry/docs

Artifact Registry replaced the older Container Registry (GCR) as Google's unified artifact management platform in 2021. GCR is still functional but deprecated for new projects.

#### Key Features
- **Multi-format:** Docker/OCI images, Maven, npm, Python (PyPI), Apt, Yum/RPM, Go modules, Helm charts, generic binary artifacts — all in one service
- **Regional and multi-regional repositories** — choose storage location for data residency and latency
- **IAM-based access control** integrated with Google Cloud IAM; supports Workload Identity for GKE
- **Vulnerability scanning** via Container Analysis (powered by Google's own CVE data + Grafeas); can be configured to block deployments with unfixed critical CVEs via Binary Authorization
- **VPC Service Controls** support to restrict registry access to specific VPC networks
- **CMEK (Customer-Managed Encryption Keys)** for compliance requirements
- **Remote repositories** — proxy and cache packages from Docker Hub, npm, PyPI, Maven Central, similar to ECR pull-through cache
- **Virtual repositories** — aggregate multiple upstream repositories behind a single URL
- Native integration with Cloud Build, Cloud Run, GKE, and Cloud Deploy

#### Pricing
- Storage: $0.10/GB/month for standard; $0.026/GB/month for Nearline
- Data transfer: free within same region; standard egress rates cross-region
- Vulnerability scanning: $0.26 per container image scanned after free tier (first 500GB storage free)

---

### Azure — Azure Container Registry (ACR) + Azure Artifacts

**Primary container registry:** Azure Container Registry (ACR)  
**Primary package registry:** Azure Artifacts (part of Azure DevOps)  
**Documentation:** https://docs.microsoft.com/azure/container-registry/ | https://docs.microsoft.com/azure/devops/artifacts/

#### ACR — Key Features
- Docker/OCI image storage and distribution
- **Three service tiers:** Basic (10GB, community support), Standard (100GB, webhooks), Premium (500GB, geo-replication, private link, customer-managed keys)
- **Geo-replication** (Premium only) — replicate registry to multiple Azure regions; reads go to nearest replica, reducing latency
- **Microsoft Defender for Containers** integration for vulnerability scanning (replaces deprecated ACR scanning)
- **ACR Tasks** — cloud-based container build service; can trigger builds on git commit, base image update, or schedule; supports multi-step task YAML
- **Private Link / Private Endpoint** support — restrict registry to specific VNets
- **Content trust** (Notary v1) for image signing; transitioning to Notary v2 / ORAS
- **OCI artifact support** via ORAS (OCI Registry as Storage) — store Helm charts, SBOMs, attestations alongside images
- Integration with AKS (attach ACR to AKS cluster with one command), Azure Pipelines, GitHub Actions

#### Azure Artifacts — Key Features
- Supports **npm, NuGet, Maven, Python (PyPI), Cargo (Rust), Universal Packages** (generic binary)
- Upstream sources — proxy from npmjs.com, PyPI, Maven Central, nuget.org
- Per-feed access control, feed scoping (organization, project, or public)
- 2GB free storage per organization; $2/GB/month thereafter
- Included in Azure DevOps; accessible via Visual Studio, Azure CLI, or REST API

#### ACR Pricing (Premium tier example)
- Storage: $0.003/GB/day (~$0.10/GB/month)
- Geo-replication: $1.667/day per replicated region
- Build minutes (ACR Tasks): $0.0001/second

---

### Comparison Table — Artifact Registries

| Feature | AWS ECR + CodeArtifact | GCP Artifact Registry | Azure ACR + Artifacts |
|---|---|---|---|
| **Container formats** | Docker, OCI | Docker, OCI, Helm | Docker, OCI, Helm (ORAS) |
| **Package formats** | npm, PyPI, Maven, NuGet, SwiftPM (CodeArtifact) | npm, PyPI, Maven, Apt, Yum, Go, Helm | npm, NuGet, Maven, PyPI, Cargo (Artifacts) |
| **Unified service** | No — ECR + CodeArtifact are separate | Yes — single AR service | Partially — ACR + Artifacts separate |
| **Vulnerability scanning** | Amazon Inspector (enhanced) | Container Analysis (Grafeas) | Microsoft Defender for Containers |
| **Geo-replication** | Yes (ECR replication rules) | Yes (multi-regional repos) | Yes (Premium tier only) |
| **Public caching/proxy** | Pull-through cache (ECR), upstream proxy (CodeArtifact) | Remote repositories | Upstream sources (Artifacts) |
| **Private networking** | VPC endpoint | VPC Service Controls | Private Link |
| **CMEK** | Yes | Yes | Yes (Premium) |
| **IAM model** | AWS IAM policies | Google Cloud IAM | Azure RBAC + AD |
| **CI/CD integration** | CodePipeline, CodeBuild | Cloud Build, Cloud Deploy | Azure Pipelines, GitHub Actions, ACR Tasks |
| **Free tier** | 500MB/month (ECR private) | 500MB/month + first 500GB scans | 2GB (Artifacts) |
| **Storage pricing** | $0.10/GB/month | $0.10/GB/month | ~$0.10/GB/month |

---

### Analysis — Which Registry for a Multi-Cloud Strategy?

For a **multi-cloud strategy**, I would choose **GCP Artifact Registry** as the primary hub, with provider-specific registries for workloads tightly coupled to each cloud.

**Reasoning:**

GCP Artifact Registry's key advantage is its **unified multi-format support** — a single service handles containers, npm, PyPI, Maven, Helm, Apt, and more under one IAM model and one storage backend. With AWS, you need ECR for containers and CodeArtifact for packages — two separate services, two billing lines, two sets of policies. Azure mirrors this split with ACR and Artifacts.

For multi-cloud, GCR's **remote repository** feature is particularly powerful: it can proxy and cache packages from Docker Hub, npm, PyPI, and Maven Central, meaning your build systems always pull from a local, compliant, cached copy regardless of where they run.

That said, in practice a multi-cloud registry strategy usually means using **each provider's native registry for workloads deployed to that provider** (ECR for EKS workloads, ACR for AKS) to avoid cross-cloud egress costs, and a **neutral harbor** (Harbor, JFrog Artifactory, or GitHub Packages) as the canonical source of truth that pushes to each cloud registry. If forced to pick one cloud-native option, Artifact Registry wins on breadth and unified management.

---

## Task 2 — Serverless Computing Platform Research

### Overview

Serverless computing lets developers deploy functions or containers that execute on-demand without provisioning or managing servers. The cloud provider handles scaling, availability, and infrastructure — you pay only for execution time.

---

### AWS — Lambda + Fargate (serverless containers)

**Primary FaaS service:** AWS Lambda  
**Serverless containers:** AWS Fargate  
**Documentation:** https://docs.aws.amazon.com/lambda/ | https://docs.aws.amazon.com/fargate/

#### AWS Lambda — Key Features
- **Runtimes:** Node.js 18/20, Python 3.10–3.12, Java 8/11/17/21, .NET 6/8, Ruby 3.2, Go (via `provided.al2023`), custom runtimes via Lambda Layers
- **Triggers:** API Gateway, ALB, S3 events, DynamoDB Streams, Kinesis, SNS, SQS, EventBridge, Cognito, CloudFront (Lambda@Edge), and 200+ other AWS services
- **Max execution duration:** 15 minutes
- **Memory:** 128MB–10,240MB; CPU scales proportionally
- **Concurrency:** Default 1,000 concurrent executions per region (soft limit, can be increased)
- **Cold start:** Typically 100–500ms for JVM; 10–50ms for Node.js/Python; SnapStart (JVM) reduces to <1s with checkpoint restore
- **Deployment:** ZIP archive or container image (up to 10GB); Lambda Layers for shared dependencies
- **Lambda@Edge / CloudFront Functions:** Run functions at Cloudfront edge locations globally with sub-1ms execution
- **Observability:** Native CloudWatch Logs + X-Ray tracing; Lambda Insights for enhanced metrics

#### AWS Fargate — Key Features
- Run containers without managing EC2 instances; works with ECS and EKS
- Pay per vCPU-second and GB-second of running container
- Good for long-running or stateful workloads that don't fit Lambda's 15-minute limit

#### Pricing (Lambda)
- **Free tier:** 1M requests/month + 400,000 GB-seconds/month forever
- Requests: $0.20 per 1M requests
- Duration: $0.0000166667 per GB-second
- Example: 10M requests × 128MB × 200ms average = ~$1.46/month

---

### GCP — Cloud Functions + Cloud Run

**Primary FaaS service:** Google Cloud Functions (Gen 2)  
**Serverless containers:** Google Cloud Run  
**Documentation:** https://cloud.google.com/functions/docs | https://cloud.google.com/run/docs

#### Cloud Functions (Gen 2) — Key Features
- Built on Cloud Run under the hood (Gen 2 = fully managed Cloud Run service)
- **Runtimes:** Node.js 16/18/20, Python 3.8–3.12, Go 1.16–1.21, Java 11/17/21, Ruby 3.0/3.2, PHP 8.1/8.2, .NET 6/8
- **Max execution duration:** 60 minutes (Gen 2); 9 minutes (Gen 1)
- **Memory:** 128MB–32GB (Gen 2)
- **Concurrency:** Up to 1,000 concurrent requests per instance (Gen 2 — unlike Lambda which is 1 req/instance)
- **Triggers:** HTTP, Pub/Sub, Cloud Storage, Firestore, Firebase, Eventarc (200+ Google services + custom events)
- **Cold start:** 100–2000ms depending on runtime; Go and Node.js tend to be fastest
- **Min instances:** Can configure minimum instances to eliminate cold starts (billed even when idle)

#### Cloud Run — Key Features
- Run any containerized workload serverlessly; full OCI container support
- **No language restrictions** — if it runs in a container, it runs on Cloud Run
- **Concurrency:** Each container instance handles up to 1,000 concurrent requests
- **Max execution duration:** Up to 60 minutes (HTTP), 60 minutes (jobs)
- **Cloud Run Jobs** for batch/one-off workloads
- **Always-on CPU** option for background processing
- **VPC connector** for private network access
- Integrates with Cloud Armor, IAP, Load Balancing natively

#### Pricing (Cloud Functions Gen 2 / Cloud Run)
- **Free tier:** 2M requests/month + 400,000 GB-seconds/month + 200,000 GHz-seconds/month
- Requests: $0.40 per 1M requests (after free tier)
- Compute: $0.00002400/vCPU-second, $0.00000250/GB-second

---

### Azure — Azure Functions + Container Apps

**Primary FaaS service:** Azure Functions  
**Serverless containers:** Azure Container Apps  
**Documentation:** https://docs.microsoft.com/azure/azure-functions/ | https://docs.microsoft.com/azure/container-apps/

#### Azure Functions — Key Features
- **Runtimes:** C# (.NET 6/7/8), JavaScript/TypeScript (Node.js 18/20), Python 3.8–3.11, Java 8/11/17/21, PowerShell 7.2, Go and Rust (via custom handlers)
- **Hosting plans:**
  - **Consumption** (serverless): pay per execution, auto-scale to 0
  - **Premium**: pre-warmed instances, VNet integration, unlimited execution duration
  - **Dedicated**: App Service Plan, always-on
- **Max execution duration:** 5 minutes (Consumption default, configurable to 10min); unlimited on Premium/Dedicated
- **Triggers:** HTTP, Timer, Blob Storage, Queue Storage, Service Bus, Event Hub, Event Grid, CosmosDB, SignalR, Dapr, and more
- **Durable Functions:** stateful orchestration using the actor/saga pattern — chains of functions with checkpointed state persisted in Azure Storage
- **Cold start:** 1–3 seconds (Consumption, .NET/Node.js); Premium plan eliminates cold starts via pre-warmed instances
- **Flex Consumption plan** (2024): new plan with faster cold starts and per-instance concurrency control

#### Azure Container Apps — Key Features
- Serverless container hosting built on Kubernetes (KEDA) under the hood
- Scale to zero; event-driven scaling via KEDA scalers (Kafka, Service Bus, HTTP, etc.)
- **Dapr integration** for microservice patterns (pub/sub, service-to-service invocation, state management)
- HTTP ingress with automatic TLS
- Revision-based traffic splitting for blue/green and canary deployments
- Good bridge between pure FaaS (Functions) and full Kubernetes (AKS)

#### Pricing (Azure Functions — Consumption)
- **Free tier:** 1M requests/month + 400,000 GB-seconds/month forever
- Requests: $0.20 per 1M requests
- Duration: $0.000016/GB-second
- Premium plan: from $0.173/hour per pre-warmed instance

---

### Comparison Table — Serverless Platforms

| Feature | AWS Lambda | GCP Cloud Functions (Gen 2) / Cloud Run | Azure Functions |
|---|---|---|---|
| **Primary FaaS** | Lambda | Cloud Functions (Gen 2) | Azure Functions |
| **Serverless containers** | Fargate | Cloud Run | Container Apps |
| **Max duration (FaaS)** | 15 min | 60 min | 10 min (Consumption) / unlimited (Premium) |
| **Memory limit** | 10 GB | 32 GB | 14 GB (Premium) |
| **Concurrency model** | 1 req/instance | 1,000 req/instance | configurable |
| **Cold start (Node.js)** | ~50–200ms | ~100–500ms | ~1,000–2,000ms |
| **Cold start mitigation** | Provisioned concurrency, SnapStart | Min instances | Premium plan (pre-warmed) |
| **Language support** | Node, Python, Java, .NET, Ruby, Go, custom | Node, Python, Go, Java, .NET, Ruby, PHP | C#, Node, Python, Java, PowerShell, Go, Rust |
| **Stateful orchestration** | Step Functions | Workflows | Durable Functions |
| **Edge execution** | Lambda@Edge, CloudFront Functions | — | — |
| **Free tier (requests)** | 1M/month | 2M/month | 1M/month |
| **Free tier (compute)** | 400K GB-s/month | 400K GB-s/month | 400K GB-s/month |
| **Pricing (per 1M req)** | $0.20 | $0.40 | $0.20 |
| **Ecosystem integration** | 200+ AWS services | 200+ Google services | Azure services + Dapr |
| **VNet integration** | Yes (Lambda in VPC) | Yes (VPC connector) | Yes (Premium plan) |

---

### Analysis — Which Serverless Platform for a REST API Backend?

For a **REST API backend**, I would choose **AWS Lambda + API Gateway**, with **GCP Cloud Run** as a strong alternative.

**Why Lambda:**

Lambda's ecosystem depth for API workloads is unmatched. API Gateway v2 (HTTP API) provides sub-millisecond routing overhead, built-in JWT/OAuth authorizers, CORS configuration, and stage-based routing — all without managing any infrastructure. Lambda's cold start for Node.js and Python is consistently the lowest of the three providers (~50–200ms), and provisioned concurrency eliminates cold starts entirely for latency-sensitive APIs.

The 15-minute execution limit is more than sufficient for REST API calls. Lambda's concurrency model (one request per instance) is simpler to reason about than Cloud Functions/Run's shared-concurrency model, which matters for correctness when writing stateful handlers.

**Why GCP Cloud Run is a compelling alternative:**

Cloud Run's **per-instance concurrency** (up to 1,000 concurrent requests per container instance) is a significant architectural advantage. For a high-traffic REST API, Cloud Run can handle traffic spikes with far fewer cold starts because existing instances absorb burst traffic rather than spawning new ones. The 60-minute execution duration is also useful if the API needs to support long-polling or streaming responses. If the team is already on GCP or prefers containerized deployments over ZIP-archive functions, Cloud Run is the better choice.

**Why not Azure Functions:**

Azure Functions' Consumption plan has the worst cold start performance of the three (~1–3 seconds for .NET), and the 10-minute execution limit (Consumption) adds complexity. The Premium plan addresses both, but adds cost and reduces the "serverless" simplicity. Azure shines for .NET shops already invested in the Microsoft ecosystem and for workloads using Durable Functions for orchestration.

---

### Reflection — Advantages and Disadvantages of Serverless

**Advantages:**

- **Zero infrastructure management** — no patching, capacity planning, or availability engineering for the compute layer
- **Auto-scaling** — functions scale from 0 to thousands of instances automatically; no pre-provisioning required
- **Pay-per-use** — idle functions cost nothing (Consumption plans); traditional servers cost money 24/7
- **Faster time-to-market** — developers focus on code, not operations; deployment is a single command
- **Built-in high availability** — all three providers run functions across multiple availability zones by default

**Disadvantages:**

- **Cold starts** — the first invocation after a period of inactivity incurs latency (50ms–3s); unacceptable for latency-sensitive APIs without provisioned/pre-warmed instances (which add cost)
- **Execution duration limits** — Lambda's 15 minutes, Azure Functions' 10 minutes (Consumption) preclude long-running workloads like video processing or large batch jobs
- **Vendor lock-in** — function code, trigger configurations, and IAM policies are provider-specific; migrating between providers requires significant rework
- **Observability complexity** — distributed traces across many short-lived function invocations are harder to debug than a monolithic application; requires investment in tracing (X-Ray, Cloud Trace, Application Insights)
- **Local development friction** — simulating cloud triggers, IAM, and service integrations locally is imperfect; tools like SAM, Functions Framework, and Azurite help but don't fully replicate production
- **Concurrency limits** — default limits (1,000 concurrent executions on Lambda) can be hit during unexpected traffic spikes and require manual limit increases
- **Statelessness requirement** — functions must be stateless between invocations; patterns requiring in-memory state need external stores (Redis, DynamoDB), adding latency and cost

**Bottom line:** Serverless is the right default for event-driven workloads, lightweight APIs, scheduled tasks, and glue code between services. It is the wrong choice for long-running, stateful, or latency-critical workloads where the overhead of cold starts and external state management outweighs the operational savings.

---

## Sources

- AWS ECR Documentation: https://docs.aws.amazon.com/ecr/latest/userguide/
- AWS CodeArtifact Documentation: https://docs.aws.amazon.com/codeartifact/latest/ug/
- AWS Lambda Documentation: https://docs.aws.amazon.com/lambda/latest/dg/
- GCP Artifact Registry Documentation: https://cloud.google.com/artifact-registry/docs
- GCP Cloud Functions Documentation: https://cloud.google.com/functions/docs
- GCP Cloud Run Documentation: https://cloud.google.com/run/docs
- Azure Container Registry Documentation: https://docs.microsoft.com/azure/container-registry/
- Azure Artifacts Documentation: https://docs.microsoft.com/azure/devops/artifacts/
- Azure Functions Documentation: https://docs.microsoft.com/azure/azure-functions/
- Azure Container Apps Documentation: https://docs.microsoft.com/azure/container-apps/
