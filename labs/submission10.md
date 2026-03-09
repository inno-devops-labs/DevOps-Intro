# Lab 10 — Cloud Computing Fundamentals



## Task 1 — Artifact Registries Research

### Service name for each cloud provider

- **AWS:** 
  - **Amazon ECR (Elastic Container Registry)** - the main registry for container images and OCI artifacts
  - **AWS CodeArtifact** - a managed package registry for npm, Maven, PyPI, NuGet, and other package formats
- **GCP:** **Google Artifact Registry** - the main universal artifact registry Google Cloud; Google explicitly recommends it as a replacement for Container Registry
- **Azure:**
  - **Azure Container Registry (ACR)** - for container images and OCI artifacts
  - **Azure Artifacts** - for batch artifacts in Azure DevOps

### Key features

**AWS**
- **ECR**: fully managed private/public container registry, image replication, authentication/policies, integration with container deployment tooling.
- **CodeArtifact**: central package repository, upstream fetch from public registries like npm, Maven Central, PyPI, NuGet, cross-account sharing, pay-as-you-go.

**GCP**
- **Artifact Registry**: universal managed registry, IAM-based access control, OCI support, integrated with Google Cloud build/runtime services, recommended successor to Container Registry.

**Azure**
- **ACR**: private registry, ACR Tasks for image builds, support for OCI/supply-chain artifacts, signing/verification guidance, enterprise Azure integrations.
- **Azure Artifacts**: feeds, upstream sources, Azure Pipelines integration, package sharing across projects/orgs.

### Supported artifact types

- **Amazon ECR:** Docker / OCI container images, OCI artifacts
- **AWS CodeArtifact:** npm, PyPI, Maven, NuGet, Swift, Ruby, Cargo, generic packages
- **Google Artifact Registry:** Docker / OCI images, Helm charts in OCI format, packages formats
- **Azure Container Registry:** Docker-compatible container images, Helm charts, OCI images, OCI artifact
- **Azure Artifacts:** NuGet, npm, Maven, Python, Cargo, Universal Packages


### Integration capabilities

**AWS ECR** integrates with container pipelines and AWS deployment tooling; CodeArtifact integrates into build systems and package managers.

**Google Artifact Registry** integrates with Cloud Build, Cloud Run, GKE, and console security dashboards.

**Azure Container Registry** integrates with container pipelines and Azure Container Registry Tasks; Azure Artifacts is closely related to Azure DevOps and Azure Pipelines.

### Comparison table highlighting similarities and differences

| Cloud Provider | Service Name | Best For | Supported Artifacts | Key Features |
|----------------|-------------|----------|---------------------|-------------|
| AWS | Amazon ECR + AWS CodeArtifact | Containers and package repositories | Docker/OCI images, npm, Maven, PyPI, NuGet, Cargo, Swift, Ruby | Managed registry, IAM access control, cross-account sharing, upstream package repositories |
| GCP | Artifact Registry | Unified artifact storage | Docker/OCI images, Helm charts, language packages | Single universal registry, IAM integration, strong integration with Cloud Build, GKE and Cloud Run |
| Azure | Azure Container Registry + Azure Artifacts | Containers and Azure DevOps packages | Docker/OCI images, Helm charts, NuGet, npm, Maven, Python, Cargo | Azure DevOps integration, ACR Tasks for image builds, OCI artifact support |

### Analysis: 

For the multi-cloud strategy, I would choose Google Artifact Registry as the closest option to the “single universal registry”, because it is initially positioned as a universal build artifacts and dependencies manager, and not as two separate services for containers and packages. This simplifies the operational model, the IAM approach, and the standardization of processes.



## Task 2 — Serverless Computing Platform Research

### Service name(s) for each cloud provider

**AWS**: **AWS Lambda** - the main AWS serverless compute service.

**GCP**:
- **Cloud Run** - the main modern serverless compute service for containers and HTTP/event workloads;
- **Cloud Run functions** — lightweight functions model for single-purpose event-driven code.

**Azure**
**Azure Functions** - the main serverless/event-driven compute service of Azure.

### Key features and capabilities

- **AWS Lambda**: Event-driven computing; provides server services, integration, and event handling.

- **Cloud Launch**: Interfaces triggered by requests or events; create both HTTP services and event-driven workloads.

- **Cloud Launch Features**: HTTP-triggered and event-driven functions.

- **Azure Functions**: Event-driven, scheduled, and triggered over HTTP; Azure separately captures triggers/bindings for HTTP, queues, storage, event grids, etc.

### Supported runtimes and languages

- **AWS Lambda**: Managed Runtimes + Custom Runtimes; AWS notes that Lambda supports multiple languages through runtimes.

- **GCP Cloud Run**: A simple language that can be used in the embedded Linux x86_64 container image; there are also supported base images/buildpacks runtimes.

- **Functions to run in the GCP cloud**: Node.js, Python, Go, Java, Ruby, PHP, etc. all the functions of the framework / listed runtime environment.

- **Azure features**: C#, Java, JavaScript, PowerShell, Python, TypeScript; also supports other languages such as Rust/Go.

### Pricing comparison

**AWS Lambda**: Defines the number of requests and the duration of their execution.

- **Launch in the cloud**: Pay as you receive, in hourly seconds and gigabytes in seconds; this is a free tier and discounts after perfect use.

- **Cloud Launch Capabilities**: To increase prices for services related to launching in the cloud.

- **Azure features**: A consumer/flexible payment system without using a server as needed; Premium services and specialized solutions with minimal costs and delays.

### Performance characteristics

- **AWS Lambda**: Maximum of 900 seconds (15 minutes).
- **Running in the cloud**: the request waiting time is less than 60 minutes.
- **Azure Features**: Default 5 minutes, maximum 10 minutes; Flex/Premium/Dedicated/Container applications can be virtually unlimited, but with HTTP-initiated responses, latency is 230 seconds due to the Azure load balancer.

### Comparison table highlighting similarities and differences

| Cloud Provider | Service | Execution Model | Supported Languages | Pricing Model | Max Execution Time | Cold Start Mitigation |
|----------------|--------|----------------|--------------------|--------------|-------------------|----------------------|
| AWS | AWS Lambda | Event-driven functions | Node.js, Python, Java, Go, .NET, Ruby, custom runtimes | Pay per request and execution time | 15 minutes | Provisioned Concurrency, SnapStart |
| GCP | Cloud Run | Serverless containers (HTTP/event-driven) | Any language via containers | Pay per vCPU-second and memory usage | Up to 60 minutes request timeout | Minimum instances |
| GCP | Cloud Run Functions | Event-driven and HTTP-triggered functions | Node.js, Python, Go, Java, Ruby, PHP | Same pricing model as Cloud Run | Depends on Cloud Run configuration | Minimum instances |
| Azure | Azure Functions | Event-driven, HTTP-triggered, scheduled | C#, Java, JavaScript, Python, PowerShell, TypeScript | Pay per execution on Consumption plan | 10 minutes on Consumption plan | Prewarmed instances on Premium plans |

### **Analysis**: Which serverless platform would you choose for a REST API backend and why?

For the REST API backend, I would choose Google Cloud Run. The reason is that Cloud Run is naturally suitable for HTTP services, supports any language through containers, works well for API/microservice workloads, provides more flexibility in the runtime environment than classic FaaS, and has a request timeout of up to 60 minutes, which is noticeably more convenient for complex backend scenarios.

### **Reflection**: What are the main advantages and disadvantages of serverless computing?

- **Advantages**
  - Do not need to manage servers;
  - Automatic scaling;
  - Pay-for-use pricing;
  - Fast integration with managed cloud services.
  
- **Disadvantages**
  - Cold starts / startup latency;
  - Cxecution time limits;
  - Cendor lock-in, especially at the triggers/bindings/events level;
  - it is more difficult to debug long-running stateful workloads and predictability under high load. Timeout limits are directly present in Lambda, Cloud Run, and Azure Functions hosting models.
