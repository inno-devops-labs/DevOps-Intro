# Lab 10 - Submission

## Task 1 - Artifact Registries Research

### Service names by cloud

- AWS: Amazon Elastic Container Registry (ECR) for container/OCI artifacts, plus AWS CodeArtifact for language package registries.
- GCP: Artifact Registry.
- Azure: Azure Container Registry (ACR) for container/OCI artifacts, plus Azure Artifacts feeds for package registries.

### Comparison Table - Artifact Registry Services

| Cloud | Service | Supported artifact types | Key features | Integrations | Pricing model (high level) |
| --- | --- | --- | --- | --- | --- |
| AWS | Amazon ECR | Docker/OCI container images and artifacts | Managed private registry, image scanning (basic/enhanced), replication, IAM/KMS security controls | ECS, EKS, Lambda container images, CodeBuild/CodePipeline | Pay for storage, data transfer, and selected actions (for example replication/signing features) |
| AWS | AWS CodeArtifact | Cargo, generic, Maven, npm, NuGet, PyPI, Ruby, Swift | Package feed hosting, upstream repositories, access control via IAM | CI/CD tools (npm, Maven/Gradle, twine, nuget/dotnet), AWS developer toolchain | Pay for storage, requests, and data transfer out |
| GCP | Artifact Registry | Docker/OCI (+ OCI Helm), Maven, npm, Python, Apt, Yum, Go, generic, others | Single managed service for many artifact formats, vulnerability scanning support, regional or multi-regional repos | GKE, Cloud Run, Cloud Build, Binary Authorization / Artifact Analysis ecosystem | Pay for storage, data transfer, vulnerability scanning (if enabled) |
| Azure | Azure Container Registry (ACR) | OCI/Docker images and related artifacts | Managed private registry, geo-replication (Premium), zone redundancy (supported regions), enterprise auth/network controls | AKS, Container Apps, App Service containers, Azure Pipelines/GitHub Actions | Tier/SKU-based model with storage and network transfer considerations |
| Azure | Azure Artifacts | NuGet, npm, Maven, Python, Cargo, Universal Packages | Multi-type feeds, upstream sources, package governance in Azure DevOps | Azure Pipelines, Azure DevOps repos and release workflows | Consumption-based billing with free storage tier and pay-as-you-go overage |

### Analysis

For a multi-cloud strategy, I would use an OCI-first baseline and keep registries close to workloads in each cloud:

- ECR for AWS runtimes,
- Artifact Registry for GCP runtimes,
- ACR for Azure runtimes.

This avoids unnecessary cross-cloud egress and gives native IAM/network integration in each platform. If one service had to be selected as a "single default" for broad artifact format coverage, GCP Artifact Registry is strong because it supports many package formats in one product.

---

## Task 2 - Serverless Computing Platform Research

### Primary serverless services by cloud

- AWS: AWS Lambda.
- GCP: Cloud Run and Cloud Run functions.
- Azure: Azure Functions.

### Comparison Table - Serverless Platforms

| Cloud | Primary service(s) | Runtimes / language support | Execution model | Performance notes | Duration limits | Pricing model |
| --- | --- | --- | --- | --- | --- | --- |
| AWS | AWS Lambda | Managed runtimes (for example Node.js, Python, Java, .NET, Ruby) + custom/container runtimes | Event-driven functions, HTTP via API Gateway/Lambda URLs, async/event triggers | Fast autoscaling, cold start depends on runtime and package size | Up to 15 minutes per invocation | Pay per request + compute duration (with free tier) |
| GCP | Cloud Run + Cloud Run functions | Cloud Run functions supports Node.js, Python, Go, Java, Ruby, PHP, .NET; Cloud Run supports any containerized language/runtime | HTTP services, background jobs, event-driven functions | Request-based or instance-based billing; scale-to-zero; good for containers and APIs | Cloud Run functions (2nd gen): up to 60 minutes for HTTP/event functions | Pay-per-use (CPU, memory, requests/data transfer with free tier components) |
| Azure | Azure Functions | C#/.NET, JavaScript/TypeScript, Python, Java, PowerShell, custom handlers | Event-driven functions + HTTP triggers + bindings to Azure services | Dynamic scale by plan; strong Microsoft ecosystem integration | Consumption plan max 10 min; other plans have larger/unbounded limits with platform caveats; HTTP response limits still apply | Consumption/Flex/Premium/Dedicated variants; consumption billed by executions + resource usage |

### Platform choice for a REST API backend

I would choose **Cloud Run** for a containerized REST API backend because:
- any language/runtime via containers,
- simple deployment model,
- scale-to-zero when idle,
- clean path from small service to production traffic.

A close alternative is AWS Lambda + API Gateway when event-driven functions and deep AWS integration are top priorities.

### Reflection - Pros and cons of serverless

#### Advantages
- No server management and lower operational overhead.
- Built-in autoscaling and fast time-to-deploy.
- Cost-efficient for bursty/variable workloads.

#### Disadvantages
- Cold start effects (runtime/workload dependent).
- Provider-specific integrations can increase lock-in.
- Hard limits (timeouts, payloads, concurrency/quotas) require architectural care.

---

## References (Official Docs)

### Artifact registries
- AWS ECR overview: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
- AWS ECR image scanning: https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html
- AWS CodeArtifact package formats: https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html
- AWS CodeArtifact pricing: https://aws.amazon.com/codeartifact/pricing/
- GCP Artifact Registry supported formats: https://cloud.google.com/artifact-registry/docs/supported-formats
- GCP Artifact Registry pricing: https://cloud.google.com/artifact-registry/pricing
- GCP Artifact Analysis (vulnerability scanning): https://cloud.google.com/artifact-registry/docs/analysis
- Azure Container Registry intro: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro
- Azure Container Registry SKU/features: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus
- Azure ACR geo-replication: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-geo-replication
- Azure Artifacts feeds and package types: https://learn.microsoft.com/en-us/azure/devops/artifacts/concepts/feeds?view=azure-devops
- Azure Artifacts storage/billing model: https://learn.microsoft.com/en-us/azure/devops/artifacts/artifact-storage?view=azure-devops

### Serverless platforms
- AWS Lambda runtimes: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
- AWS Lambda quotas: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
- AWS Lambda pricing: https://aws.amazon.com/lambda/pricing/
- Cloud Run overview: https://cloud.google.com/run/docs/overview/what-is-cloud-run
- Cloud Run functions runtimes: https://cloud.google.com/run/docs/runtimes/function-runtimes
- Cloud Run functions quotas: https://cloud.google.com/functions/quotas
- Cloud Run billing settings: https://cloud.google.com/run/docs/configuring/cpu-allocation
- Cloud Run pricing: https://cloud.google.com/run/pricing
- Azure Functions supported languages: https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages
- Azure Functions scale and hosting: https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale
- Azure Functions pricing: https://azure.microsoft.com/en-us/pricing/details/functions/
