### Task 1

#### 1.1: Artifact Registries Research

- **AWS:** `Amazon ECR` for container/OCI artifacts, and `AWS CodeArtifact` for language package registries
- **GCP:** `Artifact Registry`
- **Azure:** `Azure Container Registry` for container/OCI artifacts, and `Azure Artifacts` for language packages

#### Key features

**AWS**
- `Amazon ECR`: private/public container image registry, OCI support, IAM-based access, lifecycle policies, image scanning, replication, integration with ECS/EKS
- `AWS CodeArtifact`: managed package repository, upstream connections to public registries, IAM auth, polyglot repositories/domains, integration with CodeBuild/CodePipeline

**GCP**
- `Artifact Registry`: one managed service for multiple artifact types, regional or multi-regional repositories, cleanup policies, vulnerability scanning through Artifact Analysis, integration with Cloud Build/GKE/Cloud Run

**Azure**
- `Azure Container Registry`: private registry for container images and OCI artifacts, geo-replication, Microsoft Entra/IAM integration, ACR Tasks, signing/security features
- `Azure Artifacts`: package feeds for development teams, upstream sources, permissions, integration with Azure DevOps and Azure Pipelines

#### Supported artifact types

- **Amazon ECR:** Docker images, OCI images, OCI-compatible artifacts
- **AWS CodeArtifact:** npm, Maven, Gradle, NuGet, PyPI, twine, Swift, Ruby, Cargo, generic packages
- **GCP Artifact Registry:** container images, Java packages, Node.js packages, Python packages, Helm charts and other supported repository formats
- **Azure Container Registry:** container images, OCI artifacts, Helm/OCI-related artifacts
- **Azure Artifacts:** NuGet, npm, Maven, Python, Cargo, Universal Packages

#### Integration capabilities

- **AWS:** ECS, EKS, Lambda container images, CodeBuild, CodePipeline, IAM
- **GCP:** Cloud Build, GKE, Cloud Run, IAM, Artifact Analysis
- **Azure:** AKS, Container Apps, Azure DevOps, Azure Pipelines, Microsoft Entra ID

#### Comparison table

| Cloud | Main service(s) | Best for | Supported artifacts | Notable features | Pricing basics |
| --- | --- | --- | --- | --- | --- |
| AWS | `Amazon ECR` + `AWS CodeArtifact` | Teams already using separate AWS container + package services | Containers in ECR, packages in CodeArtifact | IAM, scanning, lifecycle policies, upstream package sources | pay for storage and related usage/requests/data transfer depending on service |
| GCP | `Artifact Registry` | One service for many artifact formats | Containers, language packages, Helm and more | unified service, cleanup policies, regional repos, integrations with GCP runtime services | pay for storage, network, scanning/usage depending on configuration |
| Azure | `Azure Container Registry` + `Azure Artifacts` | Azure-native container workflows and Azure DevOps package management | Containers/OCI in ACR, packages in Azure Artifacts | geo-replication, ACR Tasks, package feeds, upstream sources | pay based on registry tier/storage or Azure DevOps artifact usage |

#### Analysis

For a multi-cloud strategy, I would choose `GCP Artifact Registry` if I wanted one main artifact service with a simpler model across different package types. AWS and Azure split the problem into container registry + package registry, which is also fine, but a bit less uniform. If the company already used Azure DevOps heavily, then `Azure Container Registry` + `Azure Artifacts` would also make sense.

#### Sources

- AWS CodeArtifact: [https://docs.aws.amazon.com/codeartifact/latest/ug/welcome.html](https://docs.aws.amazon.com/codeartifact/latest/ug/welcome.html)
- Amazon ECR: [https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- GCP Artifact Registry: [https://cloud.google.com/artifact-registry/docs](https://cloud.google.com/artifact-registry/docs)
- GCP repository overview: [https://cloud.google.com/artifact-registry/docs/repositories](https://cloud.google.com/artifact-registry/docs/repositories)
- Azure Container Registry: [https://learn.microsoft.com/en-us/azure/container-registry/](https://learn.microsoft.com/en-us/azure/container-registry/)
- Azure Artifacts: [https://learn.microsoft.com/en-us/azure/devops/artifacts/?view=azure-devops](https://learn.microsoft.com/en-us/azure/devops/artifacts/?view=azure-devops)

### Task 2

#### 2.1: Serverless Computing Platform Research

- **AWS:** `AWS Lambda`
- **GCP:** `Cloud Run` (and Cloud Functions is now closely tied to Cloud Run)
- **Azure:** `Azure Functions`

#### Key features and capabilities

**AWS Lambda**
- event-driven serverless functions
- many AWS event source integrations
- supports zip or container image deployment
- scales automatically
- options like Provisioned Concurrency and SnapStart for some cold start scenarios

**GCP Cloud Run**
- serverless containers
- HTTP services and event-driven workloads
- scales to zero
- can run almost any language/runtime if packaged in a container
- good fit for APIs and web backends

**Azure Functions**
- event-driven serverless functions
- HTTP triggers plus many Azure event bindings
- multiple hosting plans
- strong integration with Azure services
- good for scheduled jobs, APIs, integrations, and automation

#### Supported runtimes and languages

- **AWS Lambda:** Node.js, Python, Java, .NET, Ruby, plus custom runtimes and container images
- **GCP Cloud Run:** effectively any language/runtime in a container; source-based workflows support common runtimes such as Node.js, Python, Go, Java, .NET, Ruby, PHP
- **Azure Functions:** C#, Java, JavaScript/Node.js, Python, PowerShell, TypeScript, custom handlers and container-based options

#### Pricing comparison

| Cloud | Service | Pricing model |
| --- | --- | --- |
| AWS | `AWS Lambda` | per request + execution duration, with memory affecting cost |
| GCP | `Cloud Run` | pay for requests and compute/memory used, request-based by default |
| Azure | `Azure Functions` | consumption-based pricing on executions + execution time/memory, with other hosting plan options too |

#### Performance characteristics

- **AWS Lambda:** can have cold starts, especially after idle periods, but has mature scaling and features to reduce startup impact
- **GCP Cloud Run:** can have cold starts when scaled to zero, but can keep minimum instances if needed
- **Azure Functions:** cold starts can happen on consumption plans; Premium/Flex options reduce this problem

#### Execution duration limits

- **AWS Lambda:** up to `15 minutes`
- **GCP Cloud Run:** request timeout defaults to `5 minutes`, configurable up to `60 minutes`
- **Azure Functions:** depends on hosting plan; Consumption is shorter, while newer plans allow much longer execution

#### Comparison table

| Cloud | Service | Execution model | Runtime model | Timeout | Best fit |
| --- | --- | --- | --- | --- | --- |
| AWS | `AWS Lambda` | event-driven, HTTP via API Gateway and other triggers | managed runtimes or container images | up to 15 min | small event handlers, integrations, async workflows |
| GCP | `Cloud Run` | HTTP and event-driven container workloads | any language in containers | up to 60 min request timeout | REST APIs, webhooks, containerized microservices |
| Azure | `Azure Functions` | event-driven, HTTP-triggered, scheduled jobs | managed runtimes + custom handlers/containers | plan-dependent | Azure-native apps, integrations, background jobs |

#### Analysis

For a REST API backend, I would choose `Cloud Run`. It is simple to expose an HTTP service, it works well with containers, and it is flexible if the API grows beyond a small function. `AWS Lambda` is also a strong choice, but for a more traditional API backend I think Cloud Run is a bit more straightforward.

#### Reflection

Main advantages of serverless computing:
- less server management
- automatic scaling
- pay only for actual usage
- fast to start small projects and event-driven systems

Main disadvantages:
- cold starts
- platform-specific limits and vendor lock-in
- more complex debugging/observability in some cases
- not always ideal for long-running or highly stateful workloads

#### Sources

- AWS Lambda pricing: [https://aws.amazon.com/lambda/pricing/](https://aws.amazon.com/lambda/pricing/)
- AWS Lambda quotas: [https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
- AWS Lambda runtimes: [https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
- GCP Cloud Run pricing: [https://cloud.google.com/run/pricing](https://cloud.google.com/run/pricing)
- GCP Cloud Run timeout: [https://cloud.google.com/run/docs/configuring/request-timeout](https://cloud.google.com/run/docs/configuring/request-timeout)
- GCP Cloud Run runtimes: [https://cloud.google.com/run/docs/configuring/services/runtime-base-images](https://cloud.google.com/run/docs/configuring/services/runtime-base-images)
- Azure Functions pricing: [https://azure.microsoft.com/en-us/pricing/details/functions/](https://azure.microsoft.com/en-us/pricing/details/functions/)
- Azure Functions scale/hosting: [https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale)
