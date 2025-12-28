# Lab 10 — Artifact Registries Research

## Task 1 — Artifact Registries Research

### AWS

**Service names (primary):**

- Amazon Elastic Container Registry (ECR) – main service for container images
- AWS CodeArtifact – managed package repository (npm, Maven, PyPI, etc.)

**Key features:**

- ECR: private/public repositories, IAM integration, vulnerability scanning (image scanning / Inspector), cross-region replication, lifecycle policies, Docker & OCI support, high-throughput storage, CDN optimized delivery
- CodeArtifact: multi-format support, IAM & KMS integration, proxy/cache for public registries, package versioning, CloudTrail logging

**Supported artifact types:**

- ECR: Docker/OCI container images and related OCI artifacts
- CodeArtifact: npm, Maven, PyPI, NuGet, Cargo, RubyGems, Swift, generic packages

**Integration capabilities:**

- ECR integrates with ECS, EKS, Fargate, CodeBuild, CodePipeline, IAM, KMS
- CodeArtifact integrates with CodeBuild/CodePipeline and standard developer tooling (npm, pip, mvn, etc.)

**Pricing basics:**

- ECR: pay for storage (GB-month) and data transfer; public repos have distinct pricing; replication and scanning add cost
- CodeArtifact: pay for storage and requests/download traffic; outbound data transfer billed separately

**Common use cases:**

- ECR: container deployment pipelines, ECS/EKS/Fargate workloads, multi-region image distribution
- CodeArtifact: centralized dependency management, internal/private packages, caching upstream public packages

---

### GCP

**Service name (primary):**

- Artifact Registry – unified service for containers and packages (successor to Container Registry)

**Key features:**

- Stores container images and multiple package formats; built-in vulnerability scanning (Artifact Analysis), per-location repositories, fine-grained Cloud IAM controls, regional and dual-region placement
- Tight integration with Cloud Build, Cloud Deploy, GKE, Cloud Run; on-push and on-demand scanning

**Supported artifact types:**

- Docker/OCI images, Maven, npm, PyPI (Python), APT, YUM, Go modules, Helm (OCI), generic formats

**Integration capabilities:**

- Integrated with Cloud Build (direct push), GKE/Cloud Run/Cloud Functions for deploy, Cloud IAM for access, Artifact Analysis for scanning

**Pricing basics:**

- Pay for storage (GB-month), scanning (if enhanced scanning enabled), and egress traffic; pricing differs by repository type and location

**Common use cases:**

- Unified multi-format repository, integrated CI/CD pipelines, centralized vulnerability scanning and security governance

---

### Azure

**Service names (primary):**

- Azure Container Registry (ACR) – main container registry
- Azure Artifacts (Azure DevOps) – managed feeds for packages (npm, NuGet, Maven, Python, etc.)

**Key features:**

- ACR: private Docker/OCI registry, geo-replication (Premium), Azure AD RBAC, scanning via integrations (Defender for Cloud), Helm chart support, ACR Tasks (build/patch automation), Content Trust and signing
- Azure Artifacts: private feeds, upstream proxy to public registries, Azure Pipelines integration, retention and immutability controls

**Supported artifact types:**

- ACR: OCI/Docker images, Helm charts, other OCI-compliant artifacts
- Azure Artifacts: npm, Maven, NuGet, Python (PyPI), Universal Packages

**Integration capabilities:**

- ACR integrates with AKS, App Service, Container Apps, Azure DevOps, Azure AD, external CI/CD (Docker CLI)
- Azure Artifacts integrates with Azure DevOps Pipelines and developer tooling via standard package managers

**Pricing basics:**

- ACR: tiered (Basic/Standard/Premium) with storage/throughput limits; geo-replication only in Premium; storage and egress billed; scanning via Defender billed separately
- Azure Artifacts: free base quota + paid tiers for additional storage/users

**Common use cases:**

- ACR: container delivery with geo-replication, automated image builds and patching, trusted content workflows
- Azure Artifacts: internal dependency management across teams, controlled package distribution in pipelines

---

### Comparative Table (overview)

| Criterion                    | AWS (ECR / CodeArtifact)                                                                 | GCP (Artifact Registry)                                   | Azure (ACR / Artifacts)                                                     |
|-----------------------------|-------------------------------------------------------------------------------------------|-----------------------------------------------------------|-----------------------------------------------------------------------------|
| Primary focus               | Split: ECR (containers) + CodeArtifact (packages)                                         | Unified: containers + packages                            | Split: ACR (containers) + Artifacts (packages)                              |
| Format support              | Docker/OCI; npm, Maven, PyPI, NuGet, Ruby, Cargo, Swift, generic                          | Docker/OCI, Maven, npm, PyPI, Go, APT, YUM, Helm, generic | Docker/OCI, Helm; npm, Maven, NuGet, PyPI, Universal                        |
| Security / Scanning         | ECR scanning + Inspector; CodeArtifact via IAM/KMS policies                               | Artifact Analysis (built-in vuln scanning)                | ACR scanning via Defender; Content Trust; RBAC via Azure AD                 |
| Geo-replication             | ECR cross-region replication                                                              | Regional / dual-region repository placement               | ACR geo-replication (Premium tier)                                         |
| Access control              | AWS IAM resource policies                                                                 | Cloud IAM                                                 | Azure AD / RBAC                                                            |
| CI/CD integration           | CodeBuild, CodePipeline, ECS, EKS, Fargate                                                | Cloud Build, GKE, Cloud Run, Cloud Deploy                 | Azure Pipelines, AKS, App Service, external CI/CD                           |
| Pricing (high level)        | Storage + data transfer; extra for scanning/replication                                   | Storage + scanning + egress                               | Tiered (ACR), storage/egress; Artifacts free base + paid expansion          |

---

### Analysis: Which service for a multi-cloud strategy and why?

Primary choice: Google Cloud Artifact Registry for a unified multi-format repository (containers + packages) reducing operational overhead.

Rationale:

- Single API/service for broad artifact types simplifies tooling and automation
- Built-in scanning and IAM granularity aid centralized security posture
- Easier to standardize processes across teams using multiple languages

---

## Task 2: Serverless Computing Platform Research

### AWS

**Primary services:**

* **AWS Lambda** — serverless functions (event-driven / HTTP via API Gateway).
* **AWS Fargate** — serverless compute for containers (ECS/EKS integration) for long-running or containerized workloads.

**Key features and capabilities:**

* Lambda: event-driven (triggers from S3, SNS, DynamoDB, API Gateway, EventBridge etc.), built-in auto-scaling, versions & aliases, provisioned concurrency to reduce cold starts, integrated observability (CloudWatch), and Lambda Layers for dependency sharing.
* Fargate: run containers without managing EC2, per-task resource specification, integration with ECS/EKS, good for long-running services and workloads requiring custom container images.

**Supported runtimes/languages:**

* Lambda supports many runtimes: Node.js, Python, Java, Go, Ruby, .NET, custom runtimes via Lambda Runtime API and container images up to 10 GB. Fargate runs any container image.

**Execution models & triggers:**

* Lambda: event-driven, HTTP (via API Gateway or ALB), cron (EventBridge), stream processing.
* Fargate: container-based HTTP services or background tasks (service or task mode).

**Cold start characteristics:**

* Lambda cold starts are usually small (often under 1s for lightweight runtimes) but vary with runtime, package size, VPC configuration, and language; provisioned concurrency mitigates cold starts. Fargate does not have function-style cold starts but container start time depends on image size and platform.

**Pricing basics & limits:**

* Lambda: billed per invocation and execution time (GB-seconds) plus requests; configurable memory (affects CPU) and a free tier. Maximum execution timeout: 15 minutes (900 seconds). Provisioned concurrency incurs additional charges.
* Fargate: billed per vCPU and memory resources allocated per second; pricing depends on task configuration; no short function-style invocation billing.

**Common use cases:**

* Lambda: microservices, event-driven pipelines, scheduled jobs, lightweight REST endpoints.
* Fargate: containerized microservices, long-running processes, workloads requiring custom OS/dependencies.

### GCP

**Primary services:**

* **Cloud Functions** — serverless functions (event-driven or HTTP).
* **Cloud Run** — serverless containers (fully managed) that run any stateless container image (supports HTTP and request-driven workloads).

**Key features and capabilities:**

* Cloud Functions: easy event-driven model from GCP services (Pub/Sub, Cloud Storage, Firestore), quick to deploy small functions.
* Cloud Run: runs containers with configurable concurrency per instance, can scale to zero, supports custom binaries and frameworks, provides settings to keep minimum instances to reduce cold starts.

**Supported runtimes/languages:**

* Cloud Functions: Node.js, Python, Go, Java, .NET (varies by generation); Cloud Run runs any language inside a container image.

**Execution models & triggers:**

* Cloud Functions: event-driven, HTTP-triggered, background functions. Cloud Run: HTTP-request driven services (also supports async tasks via Pub/Sub or Cloud Tasks).

**Cold start characteristics:**

* Cloud Functions and Cloud Run have cold starts; Cloud Run reduces cold starts via concurrency (multiple requests per instance) and minimum instance settings. Cold start duration depends on container image size and initialization.

**Pricing basics & limits:**

* Cloud Functions: billed per invocation, compute time (GHz-seconds / GB-seconds), and networking; timeouts vary by generation and type (short for event-driven, longer for HTTP in some cases).
* Cloud Run: billed per CPU, memory, and request concurrency usage rounded to 100ms; offers per-second billing with a free tier. Cloud Run HTTP services can be configured with long timeouts (up to 60 minutes for HTTP service instances in many configurations).

**Common use cases:**

* Cloud Functions: event-driven workloads, lightweight backends, glue logic.
* Cloud Run: production REST APIs, containerized microservices, background jobs with longer durations.

### Azure

**Primary services:**

* **Azure Functions** — serverless functions (event-driven, HTTP-triggered).
* **Azure Container Apps** and **Azure Container Instances (ACI)** — serverless container options; Container Apps is a serverless container platform with DAPR and KEDA support for event-driven autoscaling.

**Key features and capabilities:**

* Azure Functions: multiple hosting plans (Consumption, Premium, Dedicated); Durable Functions for orchestrations; integration with Event Grid, Service Bus, Storage, and HTTP triggers; Premium plan reduces cold starts and supports VNET.
* Azure Container Apps: run containers with scale-to-zero, integrated autoscaling (KEDA), Dapr support for microservice patterns, easy deploy of containerized REST services.

**Supported runtimes/languages:**

* Azure Functions supports JavaScript/TypeScript, C#, Python, Java, PowerShell, and custom containers. Container Apps run any container image and therefore any language.

**Execution models & triggers:**

* Azure Functions: event-driven (timers, storage events, HTTP, queues, etc.). Container Apps: HTTP services, event-driven using KEDA autoscaling.

**Cold start characteristics:**

* Consumption plan Functions can experience noticeable cold starts; Premium plan and pre-warmed instances mitigate this. Container Apps cold start depends on image size and platform; scale-to-zero is possible with fast scale-up when requests arrive.

**Pricing basics & limits:**

* Azure Functions Consumption plan: billed per execution and resource consumption (GB-s), includes a free grant per month; timeouts typically 5-10 minutes depending on plan (10 minutes for Consumption historically) — Premium and Dedicated plans allow longer or unlimited timeouts with different billing.
* Azure Container Apps: billed based on CPU and memory resources consumed while instances are running; supports scale to zero.

**Common use cases:**

* Azure Functions: event-driven processing, webhook handlers, lightweight APIs.
* Container Apps: containerized web APIs, microservices requiring custom dependencies or longer lifetimes.

### Comparison table (high-level)

| Criterion             |                                                             AWS Lambda / Fargate |                                                        GCP Cloud Functions / Cloud Run |                                                                                  Azure Functions / Container Apps |
| --------------------- | -------------------------------------------------------------------------------: | -------------------------------------------------------------------------------------: | ----------------------------------------------------------------------------------------------------------------: |
| Primary model         |                             Functions (Lambda) + serverless containers (Fargate) |                        Functions (Cloud Functions) + serverless containers (Cloud Run) |                                              Functions (Azure Functions) + serverless containers (Container Apps) |
| Supported languages   |                                     Many runtimes + custom runtimes / containers |                                                 Many runtimes + containers (Cloud Run) |                                                                                        Many runtimes + containers |
| Cold start mitigation |              Provisioned concurrency (Lambda), container optimizations (Fargate) |                                             Minimum instances, concurrency (Cloud Run) |                                                        Premium plan / pre-warmed instances; Container Apps config |
| Pricing model         |                    Per-invocation + duration (Lambda); per vCPU/memory (Fargate) | Per-invocation/duration (Functions); per resources used (Cloud Run, 100ms granularity) |                                Per-invocation/duration (Functions); per CPU/memory while running (Container Apps) |
| Max execution time    |                                                                   Lambda: 15 min |                                  Cloud Functions: varies; Cloud Run HTTP: up to 60 min | Functions Consumption: short (approx 5-10 min); Premium/Dedicated: longer/unbounded; Container Apps: configurable |
| Best for REST APIs    | Lambda + API Gateway (short, event-driven) or Cloud Run for container-based APIs |                                                    Cloud Run (containerized REST APIs) |                                                          Container Apps or Functions (depending on latency needs) |

### Analysis: Which serverless platform for a REST API backend and why?

For a production REST API I would choose **Google Cloud Run** (fully managed). Because, this service good when you want container flexibility, predictable cold-start behavior with concurrency, and easy scaling to zero — especially when you want to deploy frameworks or languages not supported natively by function platforms. Cloud Run’s concurrency model lets multiple requests share an instance, often giving better cost-efficiency and lower cold-start impact for HTTP APIs. See Cloud Run docs for concurrency and pricing.

### Reflection: Main advantages and disadvantages of serverless computing

**Advantages:**

* Zero server management and automatic scaling; pay-for-what-you-use billing (can reduce costs for variable workloads).
* Fast time-to-market for small services and event-driven architectures.
* Integrated observability and managed integrations with other cloud services.

**Disadvantages:**

* Cold-start latency and unpredictability for some runtimes/plans.
* Execution time and memory limits (may not suit long-running tasks without special plans or container platforms).
* Potential vendor lock-in and increased complexity for debugging/distributed tracing.
* Cost can be higher for consistently high, long-lived workloads compared with reserved instances or managed container services.
