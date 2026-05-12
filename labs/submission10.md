# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### 1.1: Main artifact registry services

For the comparison I selected the primary managed artifact registry service from each cloud provider:

- **AWS:** Amazon Elastic Container Registry, usually called **Amazon ECR**
- **Google Cloud:** **Artifact Registry**
- **Microsoft Azure:** **Azure Container Registry**, usually called **ACR**

These services are used to store and distribute container images and other build artifacts for CI/CD pipelines and cloud deployments.

---

### 1.2: Key features

**Amazon ECR** is mainly focused on container image storage. It provides private and public repositories, IAM-based permissions, image lifecycle policies, vulnerability scanning with Amazon Inspector, and replication between AWS regions or accounts.

**Google Cloud Artifact Registry** is a more general artifact management service. It supports container images as well as several package formats. It also provides IAM integration, vulnerability analysis, regional and multi-region repositories, and support for customer-managed encryption keys.

**Azure Container Registry** is Azure’s managed container registry. It supports private repositories, geo-replication, Azure role-based access control, ACR Tasks for automated image builds, and security integration with Microsoft Defender for Cloud.

---

### 1.3: Supported artifact types

| Cloud provider | Service | Supported artifact types |
|---|---|---|
| AWS | Amazon ECR | Container images, OCI artifacts, Helm charts as OCI artifacts |
| Google Cloud | Artifact Registry | Container images, Maven, npm, Python, Go, Apt, Yum, Helm, generic artifacts |
| Azure | Azure Container Registry | Container images, OCI artifacts, Helm charts, Bicep modules, WASM artifacts |

Google Cloud Artifact Registry has the widest format support because it is designed not only for containers, but also for language and OS packages.

---

### 1.4: Integration capabilities

**AWS ECR** integrates naturally with AWS services such as:

- Amazon ECS
- Amazon EKS
- AWS Lambda container images
- AWS CodeBuild
- AWS CodePipeline
- AWS App Runner
- AWS IAM

**Google Cloud Artifact Registry** integrates with:

- Cloud Build
- Cloud Run
- Google Kubernetes Engine
- Cloud Functions
- Cloud Deploy
- Google Cloud IAM
- Artifact Analysis

**Azure Container Registry** integrates with:

- Azure Kubernetes Service
- Azure Container Instances
- Azure App Service
- Azure DevOps
- GitHub Actions
- Microsoft Defender for Cloud
- Microsoft Entra ID / Azure Active Directory

---

### 1.5: Comparison table

| Feature | AWS ECR | GCP Artifact Registry | Azure Container Registry |
|---|---|---|---|
| Primary focus | Containers and OCI artifacts | Containers, language packages, OS packages | Containers and OCI artifacts |
| Container images | Supported | Supported | Supported |
| Language packages | Limited | Maven, npm, Python, Go | Limited |
| OS packages | Not a primary feature | Apt and Yum packages | Not a primary feature |
| Helm charts | Supported as OCI artifacts | Supported | Supported |
| Vulnerability scanning | Amazon Inspector | Artifact Analysis | Microsoft Defender for Cloud |
| Access control | AWS IAM | Google Cloud IAM | Azure RBAC / Entra ID |
| Replication | Cross-region replication | Regional and multi-region repositories | Geo-replication |
| CI/CD integration | CodeBuild, CodePipeline | Cloud Build, Cloud Deploy | Azure DevOps, GitHub Actions |
| Kubernetes integration | Amazon EKS | Google Kubernetes Engine | Azure Kubernetes Service |
| Pricing model | Storage, transfer, scanning | Storage, transfer, scanning | Tier-based pricing plus storage and transfer |

---

### 1.6: Analysis — choice for a multi-cloud strategy

For a multi-cloud strategy, I would not fully rely on only one cloud provider’s native registry. AWS ECR, GCP Artifact Registry, and Azure ACR are all convenient inside their own ecosystems, but using only one of them can increase vendor lock-in.

For a truly multi-cloud environment, I would prefer a cloud-independent artifact registry such as **JFrog Artifactory**, **Sonatype Nexus Repository**, or **Harbor**. These tools can work across AWS, GCP, Azure, and on-premise infrastructure. They also make it easier to apply the same access policies, retention rules, and security checks across different environments.

If I had to choose only between the three native cloud services, I would choose **Google Cloud Artifact Registry** because it supports the broadest set of artifact formats, including containers, language packages, OS packages, Helm charts, and generic artifacts.

---

## Task 2 — Serverless Computing Platform Research

### 2.1: Main serverless compute services

The main serverless compute platforms I compared are:

- **AWS:** AWS Lambda
- **Google Cloud:** Google Cloud Functions and Cloud Run
- **Azure:** Azure Functions

All of them allow developers to run application code without managing servers directly. They automatically scale based on demand and use consumption-based pricing.

---

### 2.2: Key features and capabilities

**AWS Lambda** is one of the most mature serverless platforms. It supports many event sources, automatic scaling, provisioned concurrency to reduce cold starts, container image deployment, and deep integration with AWS services.

**Google Cloud Functions** is designed for lightweight event-driven functions. It integrates well with Pub/Sub, Cloud Storage, Firebase, and Eventarc. Google Cloud also provides **Cloud Run**, which is a serverless container platform and is often better for HTTP APIs and microservices.

**Azure Functions** provides a very rich trigger and binding model. It integrates well with Azure Storage, Service Bus, Event Grid, Cosmos DB, and Application Insights. It is especially convenient for .NET and Visual Studio-based development.

---

### 2.3: Supported runtimes and languages

| Platform | Supported languages / runtimes |
|---|---|
| AWS Lambda | Node.js, Python, Java, .NET/C#, Go, Ruby, custom runtimes, container images |
| Google Cloud Functions | Node.js, Python, Go, Java, .NET, Ruby, PHP |
| Google Cloud Run | Any language or framework that can run in a container |
| Azure Functions | C#, JavaScript, TypeScript, Python, Java, PowerShell, custom handlers, containers |

---

### 2.4: Pricing comparison

| Provider | Service | Pricing model | Free tier example |
|---|---|---|---|
| AWS | AWS Lambda | Number of requests + execution duration measured in GB-seconds | 1M requests and 400,000 GB-seconds per month |
| GCP | Cloud Functions | Invocations + compute time + memory/CPU + networking | Around 2M invocations per month |
| GCP | Cloud Run | Requests + CPU/memory usage + execution time | Free monthly usage tier available |
| Azure | Azure Functions | Executions + execution time measured in GB-seconds | 1M executions and 400,000 GB-seconds per month |

All three providers use a similar pay-per-use model. Costs depend on memory size, execution time, number of requests, networking, and optional features such as provisioned concurrency or always-ready instances.

---

### 2.5: Performance characteristics

Cold starts are an important performance factor in serverless systems. A cold start happens when the provider needs to initialize a new function or container instance before handling a request.

| Platform | Cold start characteristics | Mitigation options |
|---|---|---|
| AWS Lambda | Usually stable, but depends on runtime, package size, memory, and VPC configuration | Provisioned concurrency, smaller packages, optimized runtime |
| Google Cloud Functions | Depends on runtime and function size | Minimum instances, smaller deployments |
| Google Cloud Run | Depends strongly on container startup time | Minimum instances, optimized container images |
| Azure Functions | Can vary on the Consumption plan | Premium plan, pre-warmed instances, optimized packages |

For asynchronous jobs, cold starts are usually acceptable. For user-facing REST APIs, they can directly affect response time.

---

### 2.6: Serverless comparison table

| Feature | AWS Lambda | Azure Functions | Google Cloud Functions / Cloud Run |
|---|---|---|---|
| Primary use case | Event-driven serverless compute | Event-driven apps with rich bindings | Functions and serverless containers |
| HTTP API support | API Gateway, Function URLs, ALB | HTTP triggers, API Management | HTTP functions, Cloud Run, API Gateway |
| Event sources | Very broad AWS ecosystem | Very broad Azure trigger/binding system | Pub/Sub, Storage, Firebase, Eventarc |
| Supported languages | Node.js, Python, Java, .NET, Go, Ruby | C#, JavaScript, Python, Java, PowerShell, TypeScript | Node.js, Python, Go, Java, .NET, Ruby, PHP; any language on Cloud Run |
| Container support | Lambda container images | Custom containers supported | Strong support through Cloud Run |
| Max execution timeout | 15 minutes | Depends on hosting plan | Up to 60 minutes for Cloud Run / some HTTP workloads |
| Scaling | Automatic | Automatic, depends on plan | Automatic, Cloud Run supports request concurrency |
| Cold start reduction | Provisioned concurrency | Premium plan / pre-warmed instances | Minimum instances |
| Monitoring | Amazon CloudWatch | Azure Monitor and Application Insights | Cloud Logging and Cloud Monitoring |
| Free tier | 1M requests + 400,000 GB-s | 1M executions + 400,000 GB-s | Cloud Functions commonly has 2M invocations |
| Strength | Mature ecosystem and strong AWS integrations | Best Azure/.NET integration and rich bindings | Flexible serverless containers with Cloud Run |
| Weakness | AWS lock-in and 15-minute timeout | Hosting plans can be more complex | Choosing between Functions and Cloud Run can add complexity |

---

### 2.7: Analysis — choice for a REST API backend

For a REST API backend, I would choose **AWS Lambda with Amazon API Gateway** if the application is already in the AWS ecosystem. This combination is very mature, well documented, and widely used in production. It also provides strong integration with authentication, logging, monitoring, deployment automation, and other AWS services.

However, if portability and flexibility are more important, I would choose **Google Cloud Run**. Cloud Run allows the API to be packaged as a normal container, which makes local testing and future migration easier. It also supports request concurrency, which can be efficient for web APIs.

My final choice:

- For an AWS-based production project: **AWS Lambda + API Gateway**
- For a container-first or more portable API: **Google Cloud Run**
- For a .NET/Azure-focused project: **Azure Functions + API Management**

---

### 2.8: Reflection — advantages and disadvantages of serverless computing

#### Advantages

1. **No server management**
   - The cloud provider manages infrastructure, scaling, and availability.

2. **Automatic scaling**
   - Serverless platforms scale automatically based on incoming events or requests.

3. **Cost efficiency**
   - For variable or low traffic, pay-per-use pricing can be cheaper than always-running servers.

4. **Fast development**
   - Developers can focus more on business logic instead of infrastructure management.

5. **Good cloud integrations**
   - Serverless functions integrate easily with storage, queues, databases, event buses, and monitoring tools.

#### Disadvantages

1. **Cold starts**
   - Functions may have additional startup latency after being idle.

2. **Vendor lock-in**
   - Triggers, IAM, logs, deployment configuration, and event formats are usually cloud-specific.

3. **Execution limits**
   - Serverless platforms have limits for timeout, memory, package size, and concurrency.

4. **Debugging complexity**
   - Distributed event-driven systems can be harder to debug and trace.

5. **Cost can grow at high scale**
   - For constant high traffic, serverless may become more expensive than reserved infrastructure.
