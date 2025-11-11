# Lab 10 — Cloud Computing Fundamentals
## Task 1 — Artifact Registries Research
### AWS
AWS has 2 primary services: **AWS CodeArtifact** (package manager for build artifacts like npm/Maven/PyPI/NuGet) and **Amazon ECR** (Elastic Container Registry — for Docker/OCI container images)

#### Artifact types
- CodeArtifact: npm, Maven, Gradle, pip/PyPI, NuGet, yarn, twine
- ECR: Docker images and other OCI-compliant images (supports image manifests, layers, and related OCI artifacts). Also integrates with public ECR Public Registries

#### Key features
- CodeArtifact: private package feeds, upstream sources (can proxy public registries), encryption at rest
- ECR: IAM-based access control, encryption, image vulnerability scanning (ECR image scanning integrated with Amazon Inspector), cross-region replication (ECR replication), image signing (SIGs)

#### Integration with other AWS services
- CodeArtifact: integrates with CodeBuild, CodePipeline, and can be used from EC2, Lambda, CI tools. Works with common build tools (Maven, npm, pip) in CI/CD
- ECR: integration with EKS, ECS, Fargate, CodeBuild, and IAM, ECR + CloudTrail for auditing

#### Pricing model basics
Depends on region.
- CodeArtifact: **pay-as-you-go**. Charges for storage (GB-month), per-request operations, and data transfer out
- ECR: storage (GB-month), data transfer (egress), and optionally requests or replication costs. Image scanning and private repositories may have specific fees

#### Common use cases
- Private package feeds for internal libraries (CodeArtifact). CI caching and dependency management.
- Host container images for Kubernetes (EKS), ECS tasks, CI/CD image pipeline, geographic replication for multi-region deployments (ECR)

### GCP (Google Cloud Platform)
**Artifact Registry** is a unified Google Cloud service for container images and language packages.

#### Artifact types
- Docker/OCI container images, and language package formats such as Maven, npm, Python (PyPI), Go

#### Key features
- Fully managed repositories, IAM-based access control (Cloud IAM), VPC Service Controls compatibility, regional repositories, vulnerability scanning (Container Analysis), repository-level permissions, artifact immutability/configurable retention

#### Integration with other GCP services
- Integrates with Cloud Build, GKE, Binary Authorization, Cloud IAM, Cloud KMS, and Cloud Scheduler/Cloud Functions

#### Pricing model basics
- is based on storage (GB-month) and egress
- additional costs may apply for retrieval or cross-region replication, vulnerability scanning or Container Analysis usage

#### Common use cases
- single place to store container images for GKE/Cloud Run, host internal language-specific package repositories for build pipelines (Cloud Build)
- supply-chain security with Binary Authorization + signing + scanning

### Azure
- **Azure Container Registry** (ACR): registry for Docker/OCI images and OCI artifacts
- **Azure Artifacts**: package management service within Azure DevOps

#### Artifact types
- ACR: Docker images, OCI artifacts, Helm charts
- Azure Artifacts: npm, NuGet, Maven, Python, Cargo, and Universal Packages

#### Key features
- ACR: geo-replication (ACR geo-replication), image/task automation (ACR Tasks for building images in-cloud), content trust/signing, vulnerability scanning partner integrations, network isolation via Private Link / VNet, admin/role-based access via Azure AD (Microsoft Entra)
- Azure Artifacts: feeds with access control, upstream sources (cache public registry packages), package retention/policies, integration with Azure Pipelines, storage quotas/free tiers for small teams

#### Integration with other Azure services
- ACR: Azure Kubernetes Service (AKS), Azure Pipelines/DevOps, Azure Functions, App Service, Managed Identities
- Azure Artifacts: Azure DevOps (Pipelines), Boards, Repos, CI/CD pipelines

#### Pricing model basics
- ACR: tiered SKU (Basic/Standard/Premium) with different storage/throughput/replication features. Charges by tier, storage and network egress
- Azure Artifacts: usually free up to a small storage amount (commonly 2 GB) per organization. Beyond that storage costs apply

#### Common use cases
- ACR: store and distribute container images for AKS, App Services, microservices deployments, in-cloud builds
- Azure Artifacts: host internal package feeds for CI/CD and dependency management, cache upstream public packages for reliability, share private binaries across teams

### Comparison
| Area | AWS (CodeArtifact / ECR) | GCP (Artifact Registry) | Azure (ACR Artifacts) |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary service for packages**                   |                                                                                                        **CodeArtifact** (packages: npm/Maven/PyPI/NuGet). | **Artifact Registry** supports packages (Maven, npm, PyPI, etc.).                                                           | **Azure Artifacts** (Azure DevOps) for packages (npm/Maven/NuGet/Python/Cargo).                                                            |
| **Primary service for container images**           |                                                                                                                      **ECR** (Docker/OCI images). | **Artifact Registry** (Docker/OCI images).                                                                                   | **Azure Container Registry (ACR)** (Docker/OCI).                                                                                         |
| **Vulnerability scanning / supply-chain security** |                                                            ECR scanning (Amazon Inspector integration); CodeArtifact relies on upstream/CI scans. | Container Analysis / vulnerability scanning, Binary Authorization integrations.                                              | ACR integrates with partner scanners/solutions; security via Azure AD, Private Link; Azure Artifacts relies on pipeline controls/auditing. |
| **Geo-replication**                                | ECR replication across regions; CodeArtifact has repository scopes but no ECR-style geo-replication feature (check docs for cross-region setups). | Artifact Registry supports regional repositories and can be used across regions (recommendations for replication patterns). | ACR Premium supports geo-replication; Artifacts is central to Azure DevOps organization (storage across region model).                    |
| **Identity & access control**                      |                                                                                                              AWS IAM (resource policies & roles). | Cloud IAM with repository-level permissions.                                                                                 | Azure AD (Microsoft Entra) for ACR; Azure DevOps identity/permissions for Artifacts.                                                      |
| **CI/CD integration**                              |                                                                                                        CodeBuild / CodePipeline / EKS / ECS integrations. | Cloud Build, GKE, Cloud Run, Binary Authorization integration.                                                               | Azure Pipelines, AKS, App Service, ACR Tasks.                                                                                              |
| **Pricing model (high level)**                     |                                      Storage + requests + egress (pay-as-you-go). ECR: storage tier + transfer; CodeArtifact: storage + requests. | Storage (GB-month) + egress; possibly scanning/analysis charges for some features.                                                        | ACR: SKU tier (Basic/Standard/Premium) + storage/egress; Artifacts: free small storage, then storage $/GB/month.                          |

### Analysis
Which registry service would you choose for a multi-cloud strategy and why?
- For a multi-cloud strategy, the best choice is **Google Artifact Registry**
- It features unified formats, simple auth mode and is easier to connect from any CI/CD
- For a **multi-platform flexibility**, it is critical to avoid hard vendor lock-in at the artifact layer

## Task 2 — Serverless Computing Platform Research
### AWS
- **AWS Lambda**: provides automatic scaling per-invocation, event integrations (S3, API Gateway, SNS, SQS, Kinesis, EventBridge), environment variables, Layers, versions/aliases, Provisioned Concurrency and SnapStart to reduce cold starts, CloudWatch metrics/logs

- **AWS Fargate**: run arbitrary containers with serverless infrastructure management. Per-task vCPU/memory allocation; integrates with ECS/EKS; suited for long-running or stateful containerized workloads

- **App Runner**: build and run web apps from source or image with automatic scaling and TLS, simpler than Fargate for web services

#### Runtimes
- Lambda: native runtimes include Node.js, Python, Java, Go, Ruby, .NET (C#), custom runtimes and container images
- Fargate/App Runner: any language/runtime packaged as a container image

#### Pricing model basics
- Lambda: billed per GB-second of execution (memory * time) + per-request fee
- Fargate: billed for vCPU and memory resources allocated while tasks run
- App Runner: billed by vCPU-hour and GB-hour consumed while instances are processing

#### Performance
Container services (Fargate/App Runner) have longer startup times for images but allow steady long-running workloads
- Timeouts: Lambda max timeout 15 minutes (900s). Fargate/App Runner are suitable for longer-running workloads (container lifetime)

### GCP
- **Cloud Functions**: event-driven, integrates with Pub/Sub, Cloud Storage, Firestore, Eventarc; ideal for small functions and quick event handlers
- **Cloud Run**: runs any container image that implements the HTTP contract; supports concurrency per instance (configurable), scales to zero, supports jobs
- **App Engine**: automatic scaling, flexible runs in containers, supports custom libs

#### Supported runtimes
- Cloud Functions: Node.js, Python, Go, Java, .NET, Ruby, PHP
- Cloud Run: any language/stack in a container

#### Pricing model basics
- Cloud Functions (1st/2nd gen): billed by invocations + compute (GB-s) + networking
- Cloud Run: billed by vCPU-second and memory-second while instances are handling requests
- App Engine: Standard environment has instance hours and resource quotas

#### Performance
Cloud Run supports concurrent requests per instance, allowing high request throughput with fewer instances
- Timeouts: Cloud Run request timeout default 5 minutes, max 60 minutes

### Azure
- **Azure Functions**: supports triggers (HTTP, Service Bus, Event Hub, Timer, etc.), bindings, Durable Functions for stateful orchestrations
- **Container Apps**: designed for microservices and event-driven containers
- **App Service**: provides PaaS for web apps, supports many languages

#### Supported runtimes
- Azure Functions: native support for C#, F#, JavaScript/TypeScript (Node.js), Python, Java, PowerShell
- Container Apps / App Service: any language in a container or supported runtime stacks

#### Pricing model basics
- Azure Functions: Consumption plan billed by executions + GB-s (per-second resource consumption) with free grants; Premium plan billed by vCPU/GB
- Container Apps: billed by vCPU-second and memory-second while instances are active + requests
- App Service: billed by App Service Plan tiers

#### Performance
Consumption plans autoscale with event load; Premium prewarms workers to eliminate cold starts
- Timeouts: Consumption plan default 5 minutes (max 10 minutes); Premium plan supports much longer/unbounded runtimes (configurable)

### Comparison
| Aspect                                                  |                                                                                                                                                      AWS | GCP                                                                                                                                                                       | Azure                                                                                                                                                                                                                                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary service names**                               |                                                                **AWS Lambda** (FaaS) ; **AWS Fargate** & **App Runner** (serverless containers/web apps) | **Cloud Functions** (FaaS) ; **Cloud Run** (serverless containers) ; **App Engine** (PaaS)                                                                                | **Azure Functions** (FaaS) ; **Azure Container Apps** (serverless containers) ; **App Service** (managed apps)                                                                                                                                                               |
| **Primary execution model**                             |                                                      Function-per-invocation (Lambda). Containers for long-running / web services (Fargate, App Runner). | Functions (event handlers) and container-first (Cloud Run). App Engine for opinionated web apps.                                                                          | Functions for events; Container Apps for microservices (Dapr + KEDA); App Service for managed web hosting.                                                                                                                                                                   |
| **Supported runtimes**                      |                                                                Native: Node, Python, Java, Go, Ruby, .NET, custom runtimes; containers for any language. | Cloud Functions: Node, Python, Go, Java, .NET, Ruby, PHP (varies by generation). Cloud Run: any language in a container.                                                  | Functions: C#, F#, JS/TS (Node), Python, Java, PowerShell; custom handlers allow others. Container-based services: any runtime.                                                                                                                                              |
| **Container support**                     |                                                                            Strong — Lambda supports container images; Fargate/App Runner run containers. | Excellent — Cloud Run runs any OCI container; very portable.                                                                                                              | Strong — Container Apps & App Service support containers; good for Azure-centric workloads.                                                                                                                                                                                  |
| **Billing model**                          |                                          **Lambda:** GB-seconds + per-request. **Fargate/App Runner:** vCPU-seconds + memory-seconds (+ storage/egress). | **Cloud Functions:** GB-seconds + invocations. **Cloud Run:** vCPU-seconds + memory-seconds + requests + egress.                                                          | **Functions (Consumption):** GB-seconds + executions. **Container Apps:** vCPU-seconds + memory-seconds + requests. App Service uses fixed plan tiers.                                                                                                                       |
| **Scaling model**                                       |                                               Lambda: scales by concurrent invocations (account limits apply); Fargate/App Runner scale tasks/instances. | Cloud Functions: per-invocation scaling. Cloud Run: instances scale automatically; concurrency configurable per instance (can reduce instance count).                     | Functions: Consumption auto-scales; Premium pre-warmed instances; Container Apps scale via KEDA (event-based), scale-to-zero supported.                                                                                                                                      |
| **Concurrency / throughput model**                      | Lambda: one execution per function instance (concurrency = instances). Containers (Fargate/App Runner): multiple requests per instance depending on app. | Cloud Run: configurable concurrency per instance (higher throughput per instance possible). Cloud Functions: one request per instance.                                    | Container Apps: can handle concurrent requests per replica; Functions in Consumption handle one invocation per worker (Premium can host prewarmed workers).                                                                                                                  |
| **Cold-start behavior & mitigation**                    |                                                          Cold starts can occur; mitigations: **Provisioned Concurrency**, **SnapStart** (Java), warmers. | Cold starts reduced by **startup CPU boost**, setting **min instances** for Cloud Run; Cloud Functions 2nd gen has improvements.                                          | Cold starts occur on Consumption; mitigations: **Premium** plan (prewarmed instances), keep-alive/min instances, Container Apps pre-scaling.                                                                                                                                 |
| **Max execution duration / timeouts**                   |                                         Lambda: **max 15 minutes** per invocation. Containers (Fargate/App Runner): suitable for long-running processes. | Cloud Run: **up to 60 minutes** per request (HTTP). Cloud Functions: depends on generation (shorter in 1st gen, longer in 2nd). App Engine flexible supports longer jobs. | Functions Consumption: default ~5 min (platform limits; max 10 min historically); Premium/Flexible: much longer or effectively unbounded depending on plan; Container Apps: container lifetime (suitable for long jobs). *(Check current docs for exact timeouts per plan.)* |

### Analysis
Which serverless platform would you choose for a REST API backend and why?
- **GCP** due to its best containerized APIs, fast cold starts, easy local-to-cloud portability, flexible concurrency

### Reflection
What are the main advantages and disadvantages of serverless computing?
- Advantages: no need for server management, automatic scaling, cost efficiency, high availability, event-driven design (good for reactive systems)
- Disadvantages: cold starts, resource limitations, limited control, dependence on vendor, difficulties in debugging