# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### 1.1 Main services by provider

- **AWS:** **Amazon Elastic Container Registry (ECR)**.  
  Important nuance: AWS does not use ECR as a universal package registry. ECR is focused on container and OCI artifacts, while **AWS CodeArtifact** is the AWS service for language package repositories such as Maven, npm, PyPI, and NuGet.
- **GCP:** **Google Artifact Registry**
- **Azure:** **Azure Container Registry (ACR)**

---

### 1.2 AWS — Amazon Elastic Container Registry (ECR)

**Official service name:** Amazon Elastic Container Registry (Amazon ECR)

**What it supports**
- Docker images
- OCI images
- OCI-compatible artifacts
- Public and private container repositories

**Key features**
- Managed private and public registries
- IAM-based access control and repository permissions
- Vulnerability scanning, including enhanced scanning with Amazon Inspector
- Cross-Region and cross-account replication
- High availability and AWS-native security model

**Integration capabilities**
- Works naturally with AWS container workflows and deployment pipelines
- Fits well into AWS IAM-based access management
- Commonly used alongside ECS, EKS, and CI/CD tooling in AWS

**Pricing basics**
- No upfront fees
- Main cost drivers are storage and internet data transfer
- Free tier exists for new private-repository users and public repositories

**Typical use cases**
- Storing private container images for internal deployments
- Distributing public images
- Managing OCI-based artifacts in AWS-centered environments

**Assessment**
Amazon ECR is strong when the company is mainly operating with containers and OCI artifacts inside AWS. Its biggest limitation in this comparison is scope: if “artifact registry” includes language package repositories in the same service, AWS splits that responsibility between ECR and CodeArtifact rather than giving one universal registry product.

---

### 1.3 GCP — Artifact Registry

**Official service name:** Artifact Registry

**What it supports**
- Docker / OCI images
- Helm charts packaged as OCI artifacts
- Maven packages
- npm packages
- Python packages
- Debian (Apt) packages
- RPM (Yum/DNF) packages
- Go modules
- Generic artifacts
- Kubeflow pipeline templates

**Key features**
- One registry family for both containers and language packages
- Standard repositories, remote repositories, and `gcr.io`-compatible repositories
- Vulnerability scanning through Artifact Analysis
- IAM-based access control
- Strong integration with Google Cloud build and runtime services

**Integration capabilities**
- Cloud Build
- GKE
- Cloud Run
- Compute Engine
- App Engine flexible environment

**Pricing basics**
- Pricing is based mainly on storage, data transfer, and vulnerability scanning
- Same pricing model applies across supported repository types

**Typical use cases**
- A single registry service for both application packages and container images
- CI/CD pipelines that publish multiple artifact types
- Organizations that want a simpler, more unified artifact management layer

**Assessment**
Artifact Registry is the broadest service in this comparison. It is closer to a universal artifact repository than ECR or ACR because it supports both container artifacts and many package ecosystems in one product.

---

### 1.4 Azure — Azure Container Registry (ACR)

**Official service name:** Azure Container Registry (ACR)

**What it supports**
- Docker-compatible container images
- OCI artifacts
- Helm charts stored as OCI artifacts

**Key features**
- Geo-replication for multi-region distribution
- Microsoft Entra ID authentication and Azure RBAC
- Private networking / Private Link
- Tag locking and content trust capabilities
- Optional image scanning with Microsoft Defender for Cloud
- ACR Tasks for automated builds and patching

**Integration capabilities**
- Strong fit with Azure-native deployment and identity services
- Commonly used with AKS and other Azure compute services
- Supports secure enterprise networking patterns

**Pricing basics**
- Predictable tiered pricing: **Basic**, **Standard**, and **Premium**
- Premium unlocks the most advanced enterprise features such as full geo-replication

**Typical use cases**
- Enterprise container registries in Azure
- Multi-region image distribution
- Security-focused container delivery pipelines

**Assessment**
Azure Container Registry is mature and enterprise-friendly, especially for container-heavy Azure environments. Like ECR, it is strongest for container and OCI workflows, not as a universal language-package registry.

---

### 1.5 Comparison table — Artifact Registries

| Provider | Main service | Main artifact types | Strongest features | Pricing model | Best fit |
|---|---|---|---|---|---|
| AWS | Amazon ECR | Docker images, OCI images, OCI-compatible artifacts | IAM permissions, vulnerability scanning, cross-Region and cross-account replication | Pay for storage and internet data transfer | AWS container platforms and OCI-focused workflows |
| GCP | Artifact Registry | Containers plus Maven, npm, Python, Apt, RPM, Go, generic artifacts, Kubeflow templates | Broad format support, unified registry model, vulnerability scanning, CI/CD integration | Pay for storage, data transfer, and scanning | Teams that want one service for many artifact types |
| Azure | Azure Container Registry | Docker images, OCI artifacts, Helm charts as OCI | Geo-replication, Microsoft Entra ID, RBAC, Private Link, Defender integration, ACR Tasks | Tiered SKUs: Basic, Standard, Premium | Enterprise Azure container delivery |

---

### 1.6 Analysis — Which registry would I choose for a multi-cloud strategy?

For a **multi-cloud strategy**, I would choose **Google Artifact Registry**.

**Why:**
1. It supports the widest range of artifact types in one product, so I would not need one service for containers and another one for package registries.
2. It is easier to standardize one artifact workflow across different teams when the same platform handles Docker/OCI images, language packages, OS packages, and generic artifacts.
3. Its repository model is flexible enough for centralized software supply chain control.

That said, there is an important nuance. If the company is **only** dealing with container images and OCI artifacts, then **AWS ECR** and **Azure ACR** are also strong options. In that narrower scenario, OCI compatibility matters more than broad package support, and the decision would depend more on the main cloud provider and networking/security needs.

My final choice is still **Artifact Registry**, because it is the most complete option for a genuinely mixed, multi-cloud DevOps setup.

---

## Task 2 — Serverless Computing Platform Research

### 2.1 Main services by provider

- **AWS:** **AWS Lambda**
- **GCP:** **Cloud Run**  
  For this submission, I treat Cloud Run as Google Cloud’s strongest primary serverless compute platform because it is the most flexible option for both HTTP services and event-driven workloads.
- **Azure:** **Azure Functions**

---

### 2.2 AWS — AWS Lambda

**Official service name:** AWS Lambda

**Execution model**
- Event-driven execution
- Direct invocation
- Frequently used behind HTTP endpoints through API Gateway
- Strong integration with AWS event sources

**Supported runtimes / languages**
- Managed runtimes for major languages such as Node.js, Python, Java, and .NET
- Custom runtimes are supported
- Container-image packaging is also supported

**Cold start characteristics**
- Cold starts happen when Lambda has to create a new execution environment
- AWS provides tools to reduce startup latency, especially **Provisioned Concurrency** and **Lambda SnapStart**

**Integration capabilities**
- Native integration with AWS services and event sources
- Common patterns include S3 events, DynamoDB streams, EventBridge, queues, and HTTP APIs

**Pricing basics**
- Pay per request and per GB-second of compute time
- Free tier includes monthly requests and compute usage
- Extra features such as Provisioned Concurrency add cost

**Maximum execution duration**
- Up to **900 seconds (15 minutes)** per invocation

**Typical use cases**
- Event processing
- Automation
- Lightweight APIs
- Stream and queue consumers
- Scheduled tasks

**Assessment**
Lambda is the most established FaaS platform in this comparison. It is excellent for event-driven architectures and short-lived backend logic, but it becomes less convenient when the application needs long-running HTTP requests, container-style portability, or lower lock-in.

---

### 2.3 GCP — Cloud Run

**Official service name:** Cloud Run

**Execution model**
- Request-driven services
- Event-driven services through Eventarc / Pub/Sub-style integrations
- Jobs for background and batch workloads

**Supported runtimes / languages**
- Any language, as long as it can run in a container
- Source-based deployment is also available for common runtimes such as Go, Node.js, Python, Java, .NET, and Ruby

**Cold start characteristics**
- Cold starts can happen when a service scales from zero
- Google provides **minimum instances** and **startup CPU boost** to reduce startup latency

**Integration capabilities**
- Cloud Build
- Artifact Registry
- Eventarc
- Pub/Sub
- GKE and other Google Cloud services

**Pricing basics**
- Pay for requests, CPU, and memory consumed during billed execution time
- Always-free monthly tier for services

**Maximum execution duration**
- Default request timeout is **5 minutes**
- Maximum request timeout is **60 minutes**
- Concurrency can reach **1000 requests per instance**

**Typical use cases**
- REST APIs
- Web backends
- Microservices
- Event-driven services
- Background jobs

**Assessment**
Cloud Run is the most flexible platform here. It supports serverless operation without forcing the project into a pure function model. Because it runs standard containers, it is usually the easiest option for portability, custom dependencies, and full web backends.

---

### 2.4 Azure — Azure Functions

**Official service name:** Azure Functions

**Execution model**
- Event-driven functions
- HTTP-triggered functions
- Schedule-based execution
- Rich trigger/binding model for Azure services

**Supported runtimes / languages**
- C#
- Java
- JavaScript
- PowerShell
- Python
- Custom handlers for languages such as Rust and Go

**Cold start characteristics**
- Cold starts are possible on dynamic hosting plans
- The **Premium plan** uses always-ready and prewarmed instances to effectively avoid cold starts
- Microsoft currently recommends **Flex Consumption** for new serverless function apps

**Integration capabilities**
- Strong binding/trigger model for Azure services
- Works well with storage, queues, Event Grid, and HTTP-based integration patterns
- Tight integration with Azure Monitor and Application Insights

**Pricing basics**
- Consumption and Flex Consumption plans use pay-as-you-go pricing based on executions and resource consumption
- Premium uses provisioned compute billing and removes execution charges
- Flex Consumption includes a smaller free grant than classic Consumption, but adds more control and newer capabilities

**Maximum execution duration**
- Consumption plan: default **5 minutes**, maximum **10 minutes**
- Flex Consumption and Premium: default **30 minutes**, maximum effectively **unbounded**
- Important caveat: HTTP-triggered functions still have a practical **230-second response limit** because of Azure Load Balancer timeout

**Typical use cases**
- Azure automation
- Event processing
- Scheduled jobs
- Integration layers
- Microsoft-centric cloud backends

**Assessment**
Azure Functions is a strong platform, especially for companies already invested in Azure services. It offers a very good developer experience for event-driven automation and integrations. Its main trade-off is that plan selection matters a lot: performance and cold-start behavior are very different between Consumption, Flex, and Premium.

---

### 2.5 Comparison table — Serverless Platforms

| Provider | Service | Execution model | Runtime model | Cold start story | Timeout | Pricing basics | Best fit |
|---|---|---|---|---|---|---|---|
| AWS | Lambda | Event-driven functions, often exposed through API Gateway | Managed runtimes, custom runtimes, container images | Cold starts exist; Provisioned Concurrency and SnapStart help | Up to 15 min | Per request + per GB-second | Event-driven functions and AWS-native automation |
| GCP | Cloud Run | HTTP services, event-driven services, jobs | Any language in a container; source deploy for common languages | Cold starts exist when scaling from zero; minimum instances help | Up to 60 min per request | Requests + CPU + memory | REST APIs, microservices, portable serverless backends |
| Azure | Azure Functions | Event-driven, HTTP, scheduled, trigger/binding based | Major languages + custom handlers | Cold starts on dynamic plans; Premium largely solves this | Consumption 10 min max; Flex/Premium effectively unbounded, but HTTP responses cap around 230 sec | Consumption/Flex: executions + resources; Premium: provisioned compute | Azure integrations, automation, enterprise event processing |

---

### 2.6 Analysis — Which platform would I choose for a REST API backend?

For a **REST API backend**, I would choose **Google Cloud Run**.

**Why Cloud Run is my choice**
1. **Container portability.** I can package a normal web application in a container and move it more easily across environments.
2. **Natural HTTP model.** Cloud Run feels closer to running a standard backend service than breaking the backend into many small functions.
3. **Longer request limits.** A 60-minute request timeout is far more flexible than Lambda’s 15-minute limit and Azure Functions’ 230-second practical cap for HTTP responses.
4. **Language freedom.** It supports any language that can run in a container.
5. **Operational simplicity.** I still get serverless scaling, but with more control over concurrency, rollout strategy, and startup behavior.

**Why not Lambda or Azure Functions for this specific case**
- **Lambda** is excellent for event-driven systems, but for a full REST backend it often means combining Lambda with API Gateway and adapting the app to a more function-oriented model.
- **Azure Functions** is strong, but the hosting-plan differences and HTTP response constraints make it less attractive for a general REST backend than Cloud Run.

So for a modern API backend, **Cloud Run** gives the best balance between serverless convenience and normal application architecture.

---

### 2.7 Reflection — Main advantages and disadvantages of serverless computing

#### Advantages
- **No server management:** teams focus on code instead of infrastructure.
- **Automatic scaling:** platforms scale up and down depending on demand.
- **Cost efficiency for spiky workloads:** you usually pay only when code is actually running.
- **Fast experimentation:** simple to deploy small services, handlers, and prototypes.
- **Strong cloud integrations:** event-driven architectures become easier to build.

#### Disadvantages
- **Cold starts:** first-request latency can be noticeable.
- **Vendor lock-in:** deep use of platform-specific triggers, IAM, and observability makes migration harder.
- **Execution limits:** timeouts, memory limits, and HTTP constraints can block some workloads.
- **More operational complexity at scale than it first appears:** serverless removes servers, not architecture complexity.
- **Debugging and local parity can be harder:** distributed event-driven systems are still complex systems.

**My conclusion:**  
Serverless computing is a very strong model for APIs, automation, event processing, and microservices, but it is not automatically the best choice for every workload. The best results usually come when the application is designed around the platform’s scaling model and execution limits.

---

## References (official documentation)

### Artifact registries
1. [Amazon ECR — What is Amazon ECR?](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
2. [Amazon ECR pricing](https://aws.amazon.com/ecr/pricing/)
3. [Amazon ECR image scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)
4. [Amazon ECR replication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry-settings-configure.html)
5. [AWS CodeArtifact — What is AWS CodeArtifact?](https://docs.aws.amazon.com/codeartifact/latest/ug/welcome.html)
6. [AWS CodeArtifact supported package formats](https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html)
7. [Google Artifact Registry overview](https://cloud.google.com/artifact-registry/docs/overview)
8. [Google Artifact Registry supported formats](https://cloud.google.com/artifact-registry/docs/supported-formats)
9. [Google Artifact Registry pricing](https://cloud.google.com/artifact-registry/pricing)
10. [Artifact Analysis vulnerability scanning for Artifact Registry](https://cloud.google.com/artifact-registry/docs/analysis)
11. [Azure Container Registry introduction](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
12. [Azure Container Registry concepts](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-concepts)
13. [Azure Container Registry SKU features and limits](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus)
14. [Azure Container Registry product page](https://azure.microsoft.com/en-us/products/container-registry)
15. [Microsoft Defender for container registries](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-container-registries-introduction)

### Serverless platforms
16. [AWS Lambda — How Lambda works](https://docs.aws.amazon.com/lambda/latest/dg/concepts-basics.html)
17. [AWS Lambda runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
18. [AWS Lambda pricing](https://aws.amazon.com/lambda/pricing/)
19. [AWS Lambda timeout configuration](https://docs.aws.amazon.com/lambda/latest/dg/configuration-timeout.html)
20. [AWS Lambda runtime environment lifecycle](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtime-environment.html)
21. [AWS Lambda SnapStart](https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html)
22. [API Gateway invoking Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html)
23. [Google Cloud Run overview](https://cloud.google.com/run/docs/overview/what-is-cloud-run)
24. [Cloud Run pricing](https://cloud.google.com/run/pricing)
25. [Cloud Run request timeout](https://cloud.google.com/run/docs/configuring/request-timeout)
26. [Cloud Run quotas and limits](https://cloud.google.com/run/quotas)
27. [Cloud Run startup and cold start tuning](https://cloud.google.com/run/docs/tips/general)
28. [Cloud Run language runtimes and base images](https://cloud.google.com/run/docs/configuring/services/runtime-base-images)
29. [Event-driven functions on Cloud Run with Eventarc](https://cloud.google.com/run/docs/tutorials/pubsub-eventdriven)
30. [Azure Functions overview](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)
31. [Azure Functions scale and hosting](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale)
32. [Azure Functions pricing](https://azure.microsoft.com/en-us/pricing/details/functions/)
33. [Azure Functions Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan)
34. [Azure Functions triggers and bindings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-triggers-bindings)
35. [Supported languages in Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages)
