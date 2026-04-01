# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### AWS — Amazon Elastic Container Registry (ECR)

- **Service Name:** Amazon ECR
- **Supported Artifacts:** Container images (Docker, OCI), Helm charts
- **Key Features:**
  - Integrated vulnerability scanning via Amazon Inspector
  - Image lifecycle policies for automatic cleanup
  - Cross-region and cross-account replication
  - Encryption at rest with AWS KMS
  - IAM-based access control
  - Private and public registry options (ECR Public Gallery)
- **Integration:** Tight integration with ECS, EKS, Lambda, CodeBuild, CodePipeline
- **Pricing:** $0.10/GB/month storage + $0.09/GB data transfer out

### GCP — Artifact Registry

- **Service Name:** Google Artifact Registry
- **Supported Artifacts:** Container images (Docker, OCI), Maven, npm, Python (PyPI), Go, Apt, Yum, Kubeflow Pipelines
- **Key Features:**
  - Multi-format support (not just containers)
  - Integrated vulnerability scanning via Container Analysis
  - Regional and multi-regional repositories
  - IAM and VPC Service Controls for access
  - Automatic container image signing with Binary Authorization
  - Cleanup policies based on age, tag, and usage
- **Integration:** Native with GKE, Cloud Run, Cloud Build, Cloud Deploy
- **Pricing:** $0.10/GB/month storage + network egress fees

### Azure — Azure Container Registry (ACR)

- **Service Name:** Azure Container Registry
- **Supported Artifacts:** Container images (Docker, OCI), Helm charts, OCI artifacts
- **Key Features:**
  - Geo-replication across Azure regions
  - ACR Tasks — build, test, and patch images in the cloud
  - Content trust with image signing (Notary v2)
  - Integrated vulnerability scanning via Microsoft Defender
  - Service-tier model (Basic, Standard, Premium)
  - Private link and VNet integration
- **Integration:** Native with AKS, App Service, Azure Functions, Azure DevOps
- **Pricing:** Tiered — Basic ($0.167/day), Standard ($0.667/day), Premium ($1.667/day), plus storage

### Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| Artifact types | Containers, Helm | Containers, npm, Maven, PyPI, Go, Apt, Yum | Containers, Helm, OCI |
| Vulnerability scanning | Yes (Inspector) | Yes (Container Analysis) | Yes (Defender) |
| Geo-replication | Cross-region replication | Multi-regional repos | Geo-replication (Premium) |
| Access control | IAM policies | IAM + VPC Service Controls | RBAC + Private Link |
| Image lifecycle | Lifecycle policies | Cleanup policies | Retention policies (Preview) |
| Build integration | CodeBuild | Cloud Build | ACR Tasks |
| Public registry | ECR Public Gallery | — | — |
| Pricing model | Pay-per-use (storage + transfer) | Pay-per-use (storage + transfer) | Tiered (daily rate + storage) |

### Analysis: Best Choice for Multi-Cloud Strategy

For a multi-cloud strategy, **GCP Artifact Registry** is the strongest choice because:

1. **Multi-format support** — it handles not just containers but also npm, Maven, PyPI, and Go packages in a single service. This reduces the number of tools needed across the pipeline.
2. **Standard OCI compatibility** — all three registries support OCI format, making cross-cloud image pulls straightforward.
3. **Pricing** — pay-per-use model without tier lock-in makes it cost-effective for varying workloads.

That said, for a true multi-cloud setup, using a cloud-agnostic solution like **JFrog Artifactory** or **Harbor** could avoid vendor lock-in entirely.

---

## Task 2 — Serverless Computing Platform Research

### AWS — AWS Lambda

- **Service Name:** AWS Lambda
- **Supported Runtimes:** Node.js, Python, Java, .NET, Go, Ruby, custom runtimes via Lambda Layers
- **Execution Model:** Event-driven (S3, DynamoDB, API Gateway, SQS, SNS, CloudWatch, Kinesis, etc.)
- **Key Features:**
  - Up to 10 GB memory, 6 vCPUs
  - Maximum execution: 15 minutes
  - Provisioned concurrency to reduce cold starts
  - Lambda@Edge for CDN-level compute
  - Container image support (up to 10 GB)
  - SnapStart for Java (reduces cold start from ~5s to <1s)
- **Cold Start:** ~100-500ms (interpreted languages), ~1-5s (Java/.NET without SnapStart)
- **Pricing:** $0.20 per 1M requests + $0.0000166667/GB-second

### GCP — Cloud Functions / Cloud Run

- **Service Names:** Cloud Functions (FaaS), Cloud Run (containerized serverless)
- **Supported Runtimes:**
  - Cloud Functions: Node.js, Python, Go, Java, .NET, Ruby, PHP
  - Cloud Run: Any language (container-based)
- **Execution Model:** HTTP triggers, Pub/Sub, Cloud Storage events, Firestore, Eventarc
- **Key Features:**
  - Cloud Run supports any container, not limited to specific runtimes
  - Cloud Run allows up to 60 minutes execution time
  - Minimum instances setting to eliminate cold starts
  - Concurrency up to 1000 requests per instance (Cloud Run)
  - VPC connectivity, Cloud SQL integration
  - Cloud Run Jobs for batch workloads
- **Cold Start:** ~100-300ms (Cloud Functions), ~0-500ms (Cloud Run with min instances)
- **Pricing:**
  - Cloud Functions: $0.40 per 1M invocations + $0.0000025/GB-second
  - Cloud Run: $0.00002400/vCPU-second + $0.00000250/GiB-second

### Azure — Azure Functions

- **Service Name:** Azure Functions
- **Supported Runtimes:** C#, JavaScript, TypeScript, Python, Java, PowerShell, custom handlers
- **Execution Model:** HTTP, Timer, Blob Storage, Queue, Service Bus, Event Hub, Cosmos DB triggers
- **Key Features:**
  - Durable Functions for stateful orchestration workflows
  - Premium plan with pre-warmed instances (no cold starts)
  - Maximum execution: 10 minutes (Consumption), unlimited (Premium/Dedicated)
  - KEDA-based scaling on Kubernetes (Azure Functions on AKS)
  - Native integration with Azure API Management
  - Deployment slots for staging
- **Cold Start:** ~1-3s (Consumption plan), ~0ms (Premium plan)
- **Pricing:**
  - Consumption: $0.20 per 1M executions + $0.000016/GB-second
  - Premium: from $0.173/vCPU/hour

### Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions / Cloud Run | Azure Functions |
|---------|-----------|-------------------------------|-----------------|
| Max execution time | 15 min | 60 min (Cloud Run) / 9 min (Functions) | 10 min (Consumption) / unlimited (Premium) |
| Languages | Node.js, Python, Java, Go, .NET, Ruby | Any (Cloud Run), 7 runtimes (Functions) | C#, JS/TS, Python, Java, PowerShell |
| Container support | Yes (up to 10 GB) | Yes (Cloud Run — native) | Yes (custom handlers) |
| Cold start mitigation | Provisioned Concurrency, SnapStart | Min instances (Cloud Run) | Premium plan pre-warmed instances |
| Stateful workflows | Step Functions (separate service) | Workflows (separate service) | Durable Functions (built-in) |
| Concurrency per instance | 1 request | Up to 1000 (Cloud Run) | Varies by plan |
| Free tier | 1M requests + 400K GB-s/month | 2M invocations/month | 1M executions + 400K GB-s/month |
| Pricing per 1M requests | $0.20 | $0.40 (Functions) | $0.20 |

### Analysis: Best Choice for a REST API Backend

For a REST API backend, **GCP Cloud Run** is the best choice because:

1. **Container-based** — no runtime restrictions, use any framework or language
2. **Concurrency** — handles up to 1000 concurrent requests per instance, making it much more cost-efficient than Lambda (1 request per instance) for API workloads
3. **60-minute timeout** — suitable for long-running API operations
4. **Automatic scaling to zero** — no cost when idle, just like Lambda
5. **Easy migration** — since it runs standard containers, migrating away from Cloud Run is trivial compared to rewriting Lambda function handlers

Runner-up: **Azure Functions** with Durable Functions is the best choice if the API requires complex stateful orchestration (e.g., saga patterns, human-in-the-loop workflows).

### Reflection: Advantages and Disadvantages of Serverless

**Advantages:**
- **No server management** — no patching, scaling, or capacity planning
- **Pay-per-use** — no cost when idle, ideal for variable traffic
- **Auto-scaling** — handles traffic spikes automatically from 0 to thousands of instances
- **Faster time-to-market** — focus on business logic instead of infrastructure

**Disadvantages:**
- **Cold starts** — first request after idle period has higher latency (problematic for real-time APIs)
- **Vendor lock-in** — event sources, SDK patterns, and deployment tools are provider-specific
- **Execution limits** — timeout restrictions make serverless unsuitable for long-running jobs (except Cloud Run)
- **Debugging complexity** — distributed tracing and local development are harder than traditional deployments
- **Cost at scale** — for consistently high-traffic workloads, dedicated servers can be cheaper than per-invocation pricing
