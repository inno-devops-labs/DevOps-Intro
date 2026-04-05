# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Service names, key features, supported artifact types and integration capabilities of each cloud provider
**AWS**
- *Service name*: Amazon Elastic Container Registry (ECR)
- *Key features*: Includes Basic and Enhanced vulnerability scanning (via Amazon Inspector) for OS and language-level threats, cross-region and cross-account replication, IAM-based fine-grained access control, lifecycle policies for automatic cleanup, encryption at rest and in transit, and pull-through cache for external registries.
- *Supported Artifact Types*: Focuses primarily on Docker and OCI container images, as well as OCI-compliant artifacts like Helm charts and Singularity images.
- *Integration Capabilities*: Seamless with Amazon ECS, EKS, and Lambda, and supports AWS CodeBuild, CodeDeploy, and CodePipeline, as well as third-party tools like Jenkins and GitHub Actions.

**GCP**
- *Service name*: Google Cloud Platform (GCP): Artifact Registry
- *Key Features*: Features automatic vulnerability scanning for containers (Artifact Analysis) and continuous monitoring for 30 days, fine-grained access control with IAM and VPC Service Controls for isolation, and cleanup policies for artifact lifecycle management.
- *Supported Artifact Types*: Broad support including Docker/OCI images, Maven (Java), npm (Node.js), Python (PyPI), Go modules, Apt (Debian) packages, and Helm charts.
- *Integration Capabilities*: Native integration with Cloud Build, Cloud Deploy, GKE, Cloud Run, and Cloud Functions, and supports standard package manager commands (e.g., npm, mvn, docker) with third-party CI/CD tools like Jenkins, GitLab CI, and GitHub Actions.

**Azure**
- *Service name*: Microsoft Azure: Azure Container Registry (ACR)
- *Key Features*: Notable features include geo-replication for global distribution (Premium tier), vulnerability scanning integrated with Microsoft Defender for Containers, Azure AD authentication with RBAC, Content Trust for signed images, and ACR Tasks for automated building and patching.
- *Supported Artifact Types*: Supports Docker/OCI images, OCI artifacts (including Helm charts), and any content meeting the OCI image format specification.
- *Integration Capabilities*: Native integration with Azure Kubernetes Service (AKS), Azure Container Apps, and App Service, and seamless workflow integration with Azure DevOps and GitHub Actions.

### Comparison table highlighting similarities and differences
| Feature                     | AWS ECR                                     | GCP Artifact Registry                         | Azure ACR                                   |
| --------------------------- | ------------------------------------------- | --------------------------------------------- | ------------------------------------------- |
| **Primary artifact type**   | Container images (Docker/OCI)               | Container images + language packages (npm, Maven, Python, Go, Apt) | Container images (Docker/OCI)              |
| **Vulnerability scanning**  |  Yes                                       |  Yes                                        |  Yes                                      |
| **Geo-replication**         |  Cross-region (manual/auto)                |  Regional or multi-region                   |  Auto geo-replication (Premium tier)      |
| **Access control**          | IAM                                         | IAM + VPC Service Controls                   | Azure AD + RBAC                             |
| **Lifecycle policies**      |  Yes                                       |  Yes                                        |  Yes                                      |
| **Pull-through cache**      |  Yes (unique)                              |  No                                         |  No                                       |
| **Native CI/CD integration**| CodeBuild, CodePipeline, ECS, EKS, Lambda   | Cloud Build, Cloud Deploy, GKE, Cloud Run    | Azure DevOps, GitHub Actions, AKS, App Service |
| **Public registry option**  |  ECR Public Gallery                        |  No                                         |  No                                       |
| **Language packages support**|  No                                       |  Yes (unique)                               |  No                                       |

### Analysis: Which registry service would you choose for a multi-cloud strategy and why?
I will choose GCP Artifact Registry – it offers the broadest artifact support (containers + language packages) and uses standard OCI tools, making migration slightly easier.


## Task 2 — Serverless Computing Platform Research

### Service names, key features, supported runtimes and language, pricing and performance characteristics of each serverless computing platform
**AWS**
- *Service Name*: AWS Lambda
- *Key Features*: Fully managed, event-driven compute with automatic scaling, pay-per-use pricing, and deep integration with the AWS ecosystem. Supports SnapStart for faster Java cold starts and Provisioned Concurrency for critical workloads.
- *Supported Runtimes & Languages*: Node.js, Python, Java, Go, .NET, Ruby, and custom runtimes via container images.
- *Pricing*: Pay-per-request ($0.20 per 1M requests after free tier) and compute duration (billed per 1ms). Free tier includes 1M requests/month and 400,000 GB-seconds. Up to 34% better price performance on Arm-based Graviton2 processors.
- *Performance*: Node.js cold starts ~150-300ms, Python ~200-400ms. Max timeout 15 minutes, max memory 10,240 MB, max deployment size 250 MB (unzipped), default 1,000 concurrent executions.

**GCP**
- *Service Name*: Google Cloud Functions (2nd gen)
- *Key Features*: Fully managed serverless execution environment focused on simplicity, fast deployment, and native integration with Google Cloud's event-driven architecture. Supports both 1st and 2nd generation functions.
- *Supported Runtimes & Languages*: Node.js, Python, Go, Java, Ruby, PHP, and .NET (via Cloud Run functions).
- *Pricing*: Charges only for compute time (in 100ms increments). Free tier includes 2M invocations/month, 400,000 GB-seconds, 200,000 GHz-seconds, and 5 GB outbound data.
- *Performance*: Max timeout 60 minutes (2nd gen), max memory 32 GB (2nd gen), max deployment size 500 MB, default 1,000 concurrent executions per region.

**Azure**
- *Service Name*: Azure Functions
- *Key Features*: Fully managed, event-driven serverless compute service with flexible hosting plans (Consumption, Premium, Dedicated). Deep integration with .NET ecosystem and strong enterprise/hybrid cloud capabilities.
- *Supported Runtimes & Languages*: C#, JavaScript/TypeScript, Python, Java, PowerShell, and custom handlers (supports other languages like Rust and Go). Native support for .NET Framework via isolated worker model.
- *Pricing*: Pay-per-execution and GB-seconds (billed per 100ms). Free tier includes 1M executions/month and 400,000 GB-seconds. Premium plans offer pre-warmed instances for cold start elimination.
- *Performance*: Max timeout unlimited (Premium plan) / 15 minutes (Consumption), max memory 14 GB (Premium), max deployment size 1.5 GB, default 200 concurrent executions per instance (scales instances horizontally).

### Comparison table highlighting similarities and differences
| Feature                     | AWS Lambda                                     | Google Cloud Functions (2nd gen)              | Azure Functions                              |
| --------------------------- | ---------------------------------------------- | --------------------------------------------- | -------------------------------------------- |
| **Official service name**   | AWS Lambda                                     | Google Cloud Functions                               | Azure Functions                              |
| **Key features**            | • Event-driven, auto-scaling<br>• SnapStart (faster Java cold starts)<br>• Provisioned Concurrency<br>• Graviton2 (Arm) support | • Simple deployment, event-driven<br>• 1st & 2nd gen options<br>• Native GCP events (Pub/Sub, Storage)<br>• Long-running support (60 min) | • Multiple hosting plans (Consumption, Premium, Dedicated)<br>• Pre-warmed instances (Premium)<br>• Durable Functions (orchestration)<br>• Hybrid & edge support |
| **Supported runtimes & languages** | Node.js, Python, Java, Go, .NET, Ruby, custom containers | Node.js, Python, Go, Java, Ruby, PHP, .NET (via Cloud Run functions) | C#, JavaScript, Python, Java, PowerShell, custom handlers (Rust, Go, etc.) |
| **Pricing (simplified)**    | Pay per request + compute duration (1ms increments)<br>Free: 1M requests/month + 400k GB-s | Compute time (100ms increments)<br>Free: 2M invocations/month + 400k GB-s + 200k GHz-s | Pay per execution + GB-s (100ms increments)<br>Free: 1M executions/month + 400k GB-s |
| **Max timeout**             | 15 minutes                                     | 60 minutes                                   | Unlimited (Premium plan) / 15 min (Consumption) |
| **Max memory**              | 10,240 MB                                      | 32 GB                                        | 14 GB (Premium) / 1.5 GB (Consumption)      |
| **Max deployment size**     | 250 MB (unzipped)                              | 500 MB                                       | 1.5 GB                                       |
| **Default concurrency**     | 1,000 (soft limit, adjustable)                 | 1,000 per region (adjustable)                | 200 per instance (scales out horizontally)   |
| **Cold start mitigation**   | SnapStart (Java), Provisioned Concurrency      | None native (use min instances)              | Premium plan pre-warmed instances            |
| **Billing granularity**     | 1 ms                                           | 100 ms                                       | 100 ms                                       |

### Analysis: Which serverless platform would you choose for a REST API backend and why?
I will choose AWS Lambda, because it provides best API Gateway integration, fastest cold starts (SnapStart/Provisioned Concurrency), finest billing (1ms), and Graviton2 price/performance.

### Reflection: What are the main advantages and disadvantages of serverless computing?
**Advantages**
- *No infrastructure management* – No servers, OS patches, or capacity planning. Focus only on code.
- *Automatic scaling* – Scales from zero to thousands of concurrent executions without configuration.
- *Pay-per-use pricing* – Billed only for actual compute time and requests (not idle time). Can be cheaper for sporadic or variable workloads.
- *Faster time-to-market* – Deploy individual functions quickly; ideal for event-driven and microservices architectures.
- *Built-in high availability* – Cloud provider handles redundancy across availability zones.

**Disadvantages**
- *Cold starts* – Initial latency when a function is invoked after being idle (can be 100ms to several seconds). Mitigations exist but add complexity/cost.
- *Execution limits* – Timeout (typically 15‑60 min), memory, and deployment size restrictions. Not suitable for long-running or stateful workloads.
- *Vendor lock-in* – Tight coupling to provider-specific services (API Gateway, IAM, event sources). Migrating is difficult.
- *Debugging & monitoring* – Harder to trace distributed executions; requires specialized tools (e.g., AWS X-Ray, Azure Application Insights).
- *Cost at high scale* – For consistently high traffic (24/7), dedicated servers or containers are often cheaper than pay-per-invocation.
- *Complexity for stateful workflows* – Requires external databases or orchestration (e.g., Step Functions, Durable Functions) for multi-step transactions.