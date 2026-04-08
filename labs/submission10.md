# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research (5 pts)

### Service Names by Cloud Provider

| Cloud Provider | Artifact Registry Service |
|----------------|---------------------------|
| AWS | Amazon Elastic Container Registry (ECR) |
| Google Cloud | Artifact Registry |
| Microsoft Azure | Azure Container Registry (ACR) |

### Key Features

**AWS ECR:**
- Fully managed Docker container registry
- Integration with IAM for access control
- Lifecycle policies to auto-delete old images
- Cross-region replication
- Vulnerability scanning (Basic free, Enhanced paid)
- Supports OCI artifacts and Docker images

**Google Artifact Registry:**
- Universal artifact manager (containers + packages)
- Multi-region repository support
- Integration with Cloud Build, GKE, Cloud Run
- Vulnerability scanning via Container Analysis API
- Supports Docker, npm, Maven, Python, Go

**Azure ACR:**
- Managed private Docker registry
- Three SKU tiers: Basic, Standard, Premium
- Geo-replication (Premium SKU only)
- ACR Tasks for cloud-native builds
- Helm chart repository support
- Integration with Azure Defender

### Supported Artifact Types

| AWS ECR | Google Artifact Registry | Azure ACR |
|---------|--------------------------|-----------|
| Docker images | Docker images | Docker images |
| OCI artifacts | OCI artifacts | OCI artifacts |
| - | npm packages | Helm charts |
| - | Maven packages (Java) | - |
| - | Python packages | - |
| - | Go modules | - |

### Pricing Details

**AWS ECR Pricing:**
- Storage: $0.10 per GB/month
- Data transfer: $0.09 per GB to internet (first GB free)
- Vulnerability scanning (Basic): Free
- Vulnerability scanning (Enhanced): $0.10 per image scan
- Free tier: 500 MB for 12 months

**Google Artifact Registry Pricing:**
- Storage: $0.10 per GB/month (regional), $0.14 per GB/month (multi-region)
- Data transfer: Standard egress rates apply
- Vulnerability scanning: Included with Container Analysis API
- No free tier (but new users get $300 credits)

**Azure ACR Pricing (three SKUs):**

| SKU | Storage included | Price | Geo-replication | Private endpoints |
|-----|-----------------|-------|-----------------|-------------------|
| Basic | 10 GB | ~$5/month | No | No |
| Standard | 100 GB | ~$10/month | No | No |
| Premium | 500 GB | ~$15/month | Yes | Yes |

- Additional storage: ~$0.10 per GB/month
- Data transfer: Standard Azure egress rates

### Integration Capabilities

**AWS ECR:**
- Works with ECS, EKS, Lambda, Fargate
- IAM for access control
- Cross-account replication
- Lifecycle policies

**Google Artifact Registry:**
- Works with GKE, Cloud Run, Cloud Build
- IAM for repository-level permissions
- Automatic vulnerability scanning on push
- Image streaming for faster GKE startup

**Azure ACR:**
- Works with AKS, App Service, Container Instances
- Azure AD integration
- ACR Tasks for builds
- Premium SKU adds geo-replication and private links

### Comparison Table

| Category | AWS ECR | Google Artifact Registry | Azure ACR |
|----------|---------|--------------------------|-----------|
| Primary use | Container images | Universal artifacts | Container + Helm |
| Artifact types | Docker, OCI | Docker, npm, Maven, Python, Go | Docker, OCI, Helm |
| Security scanning | Basic (free), Enhanced (paid) | Container Analysis API | Microsoft Defender |
| Multi-region | Cross-region replication | Multi-region repositories | Only in Premium |
| Free tier | 500 MB for 12 months | No | Basic SKU starts at ~$5 |
| Best for | AWS-native workloads | Multi-artifact workflows | Azure/.NET ecosystems |

### Analysis: Which registry for multi-cloud strategy?

I would choose Google Artifact Registry for a multi-cloud strategy.

Reasons:
1. Supports many artifact types (Docker, npm, Maven, Python, Go) in one place
2. Works well with any CI/CD tool (GitHub Actions, GitLab CI)
3. Less vendor lock-in compared to AWS ECR
4. Multi-region repositories give one endpoint for global teams

Alternative: Use GitHub Container Registry (GHCR) — works across all clouds, 500 MB free storage.

## Task 2 — Serverless Computing Platform Research (5 pts)

### Service Names by Cloud Provider

| Cloud Provider | Serverless Compute Service |
|----------------|---------------------------|
| AWS | AWS Lambda |
| Google Cloud | Cloud Functions (2nd gen) |
| Microsoft Azure | Azure Functions |

### Key Features

**AWS Lambda:**
- Run code without servers
- Automatic scaling from zero to thousands
- 15 minute max timeout
- 10 GB max memory
- Integrates with 200+ AWS services
- SnapStart for Java (reduces cold starts)

**Google Cloud Functions (2nd gen):**
- Built on Cloud Run infrastructure
- 60 minute timeout
- 32 GB max memory
- Up to 1,000 concurrent requests per instance
- Automatic HTTPS endpoint generation

**Azure Functions:**
- Multiple hosting plans (Consumption, Premium, Dedicated)
- Unlimited timeout on Premium plan
- 14 GB max memory (Premium)
- Durable Functions for stateful workflows
- Bindings for declarative connections

### Supported Runtimes

| AWS Lambda | Google Cloud Functions | Azure Functions |
|------------|------------------------|-----------------|
| Node.js | Node.js | Node.js |
| Python | Python | Python |
| Java | Java | Java (C#) |
| Go | Go | PowerShell |
| Ruby | Ruby | TypeScript |
| .NET | PHP | C# |

### Pricing Details

Free tier (all three providers):
- 1 million requests per month
- 400,000 GB-seconds of compute time

After free tier — AWS Lambda:
- Requests: $0.20 per 1 million requests
- Compute: $0.0000166667 per GB-second
- Example (128 MB, 100ms, 10M requests): ~$4.08/month

After free tier — Google Cloud Functions:
- Requests: $0.40 per 1 million requests (2nd gen)
- Compute: $0.000017 per GB-second
- Example: similar to AWS Lambda

After free tier — Azure Functions (Consumption plan):
- Requests: $0.20 per 1 million requests
- Compute: $0.000016 per GB-second
- Example: similar to AWS Lambda

Azure Functions Premium plan:
- Dedicated resources: ~$20-50/month depending on instance size
- Unlimited timeout, VNet integration, better performance

### Performance Characteristics

| Characteristic | AWS Lambda | Google Cloud Functions | Azure Functions |
|----------------|------------|------------------------|-----------------|
| Max memory | 10,240 MB (10 GB) | 32 GB (2nd gen) | 14 GB (Premium) |
| Max timeout | 15 minutes | 60 minutes (2nd gen) | Unlimited (Premium) |
| Cold start (Node.js) | 200-400ms | <200ms (2nd gen) | 500ms-15s |
| Concurrency | 1,000 default | 1,000 per instance | 200 per instance |

### Comparison Table

| Category | AWS Lambda | Google Cloud Functions | Azure Functions |
|----------|------------|------------------------|-----------------|
| Best for | AWS event-driven apps | Simple APIs | Enterprise .NET |
| Timeout | 15 min max | 60 min max | Unlimited (Premium) |
| Memory | 10 GB max | 32 GB max | 14 GB max (Premium) |
| Cold starts | 200-400ms | <200ms | 500ms-15s |
| Orchestration | Step Functions | Cloud Workflows | Durable Functions |

### Analysis: Which serverless platform for a REST API backend?

I would choose Google Cloud Functions (2nd generation) for a REST API backend.

Reasons:
1. Up to 1,000 concurrent requests per instance = better performance
2. 60 minute timeout is enough for most APIs
3. Simpler to use than AWS Lambda
4. Lower cold start latency (<200ms)

Alternative recommendations:
- For AWS-heavy infrastructure → AWS Lambda (most mature)
- For enterprise .NET shops → Azure Functions

### Reflection: Advantages and Disadvantages of Serverless Computing

**Advantages:**
1. No infrastructure management — no servers to patch or scale
2. Automatic scaling — from zero to thousands of executions
3. Pay-per-use pricing — no cost when idle
4. Faster time-to-market — focus only on code
5. Built-in high availability — cloud providers handle redundancy

**Disadvantages:**
1. Cold start latency — first request after idle is slow (200ms-15s)
2. Execution limits — timeout (15-60 min) and memory (10-32 GB)
3. Vendor lock-in — each platform has unique APIs
4. Harder to debug — distributed tracing is complex
5. Cost at scale — high-volume workloads may be cheaper with dedicated servers

**When to use serverless:**
- Spiky, unpredictable traffic
- Event-driven processing (file uploads, database changes)
- APIs and microservices
- Scheduled batch jobs

**When NOT to use serverless:**
- Constant, predictable high traffic (use containers instead)
- Long-running computations (>60 minutes)
- Ultra-low latency requirements (<10ms)
- Applications needing GPU or specialized hardware
