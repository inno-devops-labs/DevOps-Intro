# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Overview

An artifact registry is a centralized repository for storing, managing, and distributing build artifacts — container images, language packages (npm, Maven, PyPI), and binary files. Each major cloud provider offers its own managed registry service.

---

### AWS — Amazon Elastic Container Registry (ECR)

**Official service:** Amazon ECR (+ AWS CodeArtifact for language packages)

**Supported artifact types:**
- Docker/OCI container images
- Helm charts
- npm, Maven, PyPI, NuGet, RubyGems, Swift packages (via CodeArtifact)

**Key features:**
- Automated vulnerability scanning powered by Amazon Inspector
- Lifecycle policies for automatic image cleanup
- Cross-region and cross-account replication
- Fine-grained access control via IAM policies
- Encryption at rest using AWS KMS
- Pull-through cache from public registries (Docker Hub, ECR Public)

**Integration:** Native with ECS, EKS, Lambda, CodePipeline, CodeBuild

**Pricing:** Storage at $0.10/GB per month; data transfer charges apply for cross-region pulls

---

### GCP — Google Artifact Registry

**Official service:** Google Artifact Registry (successor to Container Registry)

**Supported artifact types:**
- Docker/OCI container images
- Maven, npm, PyPI, Apt, Yum packages
- Helm charts
- Generic binary files

**Key features:**
- Integrated vulnerability scanning via Container Analysis API
- Regional and multi-regional repository options
- CMEK (Customer-Managed Encryption Keys) support
- VPC Service Controls for network-level isolation
- Artifact streaming for faster container startup in GKE
- Fine-grained IAM roles per repository

**Integration:** Native with Cloud Build, GKE, Cloud Run, Cloud Deploy

**Pricing:** Storage at $0.10/GB per month; no charge for data transfer within the same region

---

### Azure — Azure Container Registry (ACR)

**Official service:** Azure Container Registry (+ Azure Artifacts for packages)

**Supported artifact types:**
- Docker/OCI container images
- Helm charts
- OCI artifacts (general purpose)
- npm, Maven, NuGet, PyPI, Universal Packages (via Azure Artifacts)

**Key features:**
- Microsoft Defender for Containers provides vulnerability scanning
- Geo-replication across Azure regions (Premium tier)
- Content trust and image signing
- Private endpoints via Azure Private Link
- Auto-purge policies for untagged images
- Tasks feature for cloud-based image building and patching

**Integration:** Native with AKS, Azure DevOps, GitHub Actions, Azure Pipelines

**Pricing:** Three tiers — Basic ($0.167/day), Standard ($0.667/day), Premium ($1.667/day); storage included per tier

---

### Comparison Table — Artifact Registries

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---|---|---|---|
| Container images | ✅ | ✅ | ✅ |
| Language packages | Via CodeArtifact | ✅ Built-in | Via Azure Artifacts |
| Vulnerability scanning | ✅ Amazon Inspector | ✅ Container Analysis | ✅ Defender for Containers |
| Geo-replication | ✅ | ✅ Multi-region | ✅ Premium tier only |
| Private networking | ✅ VPC endpoints | ✅ VPC Service Controls | ✅ Private Link |
| Image signing | ✅ | ✅ | ✅ Content Trust |
| Pricing model | Pay per GB + transfer | Pay per GB | Fixed daily rate by tier |
| Native CI/CD | CodePipeline/CodeBuild | Cloud Build | Azure DevOps / GitHub Actions |

---

### Analysis — Which Registry Would I Choose for a Multi-Cloud Strategy?

I would go with **Google Artifact Registry**. The main reason is that it handles both container images and language packages in one place — with AWS you end up using ECR and CodeArtifact separately, which adds complexity to pipeline configuration. For a multi-cloud setup where simplicity matters, having one unified service is a real advantage.

Another thing that stood out to me is that GCP doesn't charge for data transfer within the same region. In a CI/CD pipeline where images get pulled constantly, that adds up. The artifact streaming feature for GKE is also something AWS and Azure don't really have an equivalent for — it speeds up container startup which is noticeable in practice.

That said, if the team is already deep in AWS, ECR is the obvious pragmatic choice just because of how well it integrates with IAM, ECS, and EKS without any extra setup.

---

## Task 2 — Serverless Computing Platform Research

### Overview

Serverless computing allows developers to deploy code without provisioning or managing servers. The cloud provider handles infrastructure, scaling, and availability automatically. Billing is based on actual execution rather than reserved capacity.

---

### AWS — AWS Lambda

**Official service:** AWS Lambda (+ AWS Fargate for container-based serverless)

**Supported runtimes:** Node.js, Python, Java, Go, Ruby, .NET, custom runtimes via Lambda Layers

**Execution model:**
- Event-driven: triggered by S3, DynamoDB, SQS, SNS, API Gateway, EventBridge, and 200+ sources
- HTTP via API Gateway or Lambda Function URLs

**Key characteristics:**
- Maximum execution duration: 15 minutes
- Memory: 128 MB – 10,240 MB (CPU scales proportionally)
- Cold start: typically 100ms–1s depending on runtime and package size
- Concurrency: up to 10,000 simultaneous executions per region (soft limit)
- SnapStart feature for Java reduces cold starts by up to 90%

**Pricing:** $0.20 per 1M requests + $0.0000166667 per GB-second of execution

**Integration:** Native with virtually all AWS services; extensive ecosystem

---

### GCP — Google Cloud Functions + Cloud Run

**Official services:** Cloud Functions (lightweight), Cloud Run (container-based serverless)

**Supported runtimes:** Node.js, Python, Go, Java, Ruby, PHP, .NET (Cloud Functions); any language via container (Cloud Run)

**Execution model:**
- HTTP triggers, Pub/Sub events, Cloud Storage events, Firestore triggers
- Cloud Run supports long-running request handling and WebSockets

**Key characteristics:**
- Cloud Functions max duration: 60 minutes (2nd gen)
- Cloud Run max duration: 60 minutes per request
- Cold start: generally faster than AWS Lambda for interpreted languages
- Minimum instances option to eliminate cold starts
- Cloud Run scales to zero by default

**Pricing:** Cloud Functions — $0.40 per 1M requests + compute time; Cloud Run — per vCPU-second and memory-second

**Integration:** Cloud Build, Pub/Sub, Eventarc, Firebase, BigQuery

---

### Azure — Azure Functions

**Official service:** Azure Functions (+ Azure Container Apps for container-based serverless)

**Supported runtimes:** C#, JavaScript/Node.js, Python, Java, PowerShell, TypeScript, custom handlers

**Execution model:**
- HTTP triggers, Timer triggers, Queue/Service Bus triggers, Event Grid, Blob Storage, CosmosDB, and more
- Durable Functions extension enables stateful workflows

**Key characteristics:**
- Maximum execution duration: unlimited on Premium/Dedicated plans; 10 minutes on Consumption plan
- Memory: up to 14 GB on Premium plan
- Cold start: comparable to AWS Lambda; Premium plan keeps instances warm
- Durable Functions is a unique feature for orchestrating complex workflows

**Pricing (Consumption plan):** $0.20 per 1M executions + $0.000016 per GB-second

**Integration:** Azure DevOps, Logic Apps, Event Grid, Service Bus, CosmosDB, Azure API Management

---

### Comparison Table — Serverless Platforms

| Feature | AWS Lambda | GCP Cloud Functions / Cloud Run | Azure Functions |
|---|---|---|---|
| Max execution time | 15 min | 60 min | 10 min (Consumption) / unlimited (Premium) |
| Container support | ✅ Container images up to 10GB | ✅ Cloud Run (native) | ✅ Container Apps |
| Supported languages | 8+ runtimes + custom | 8+ runtimes + any (Cloud Run) | 7+ runtimes + custom |
| Cold start mitigation | SnapStart (Java), Provisioned Concurrency | Min instances (Cloud Run) | Premium plan (always warm) |
| Stateful workflows | AWS Step Functions (separate) | Cloud Workflows (separate) | ✅ Durable Functions (built-in) |
| Max memory | 10,240 MB | 32 GB (Cloud Run) | 14 GB (Premium) |
| Pricing base | $0.20/1M requests | $0.40/1M requests | $0.20/1M requests |
| Event sources | 200+ AWS services | Pub/Sub, Eventarc, Firebase | 30+ Azure services + Event Grid |
| Free tier | 1M requests/month | 2M requests/month | 1M requests/month |

---

### Analysis — Which Platform Would I Choose for a REST API Backend?

For a REST API backend I'd pick **AWS Lambda with API Gateway**. Honestly the main reason is how battle-tested it is — Lambda has been around since 2014 and there's a huge amount of community resources, examples, and tooling around it (Serverless Framework, AWS SAM). When something breaks at 2am it's much easier to find an answer for Lambda than for the other two.

The API Gateway integration is also genuinely good — request validation, throttling, and caching are all configurable without writing extra code. And the observability story with CloudWatch and X-Ray is solid enough that I wouldn't need to set up anything extra just to understand what's happening in production.

The 15-minute execution limit is a real constraint but for a REST API it's not a problem — if a single request takes more than a few seconds something is already wrong architecturally.

If I were starting fresh on GCP I'd seriously consider Cloud Run instead, mostly because the 60-minute timeout gives more flexibility and cold starts are less of an issue with minimum instances configured.

---

### Reflection — Advantages and Disadvantages of Serverless

**Advantages:**

- **No infrastructure management** — developers focus on code, not servers, patching, or capacity planning.
- **Automatic scaling** — scales from zero to thousands of concurrent executions without configuration.
- **Cost efficiency at low traffic** — pay only for actual execution time; idle functions cost nothing.
- **Faster time to market** — reduces operational overhead and deployment complexity.
- **Built-in high availability** — managed by the cloud provider across multiple availability zones.

**Disadvantages:**

- **Cold starts** — functions that haven't been invoked recently take longer to respond on first call, which can impact latency-sensitive APIs.
- **Execution time limits** — not suitable for long-running processes (e.g., video processing, large ETL jobs) without architectural workarounds.
- **Vendor lock-in** — heavy use of provider-specific triggers and integrations makes migration difficult.
- **Debugging complexity** — distributed, ephemeral execution makes tracing bugs harder than in traditional server environments.
- **Limited local development** — emulating cloud triggers and services locally requires additional tooling and is rarely a perfect match.
- **Cost unpredictability at scale** — at very high traffic volumes, serverless can become more expensive than reserved instances.

---

## Sources

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS CodeArtifact Documentation](https://docs.aws.amazon.com/codeartifact/)
- [Google Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Google Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
