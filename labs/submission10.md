# Task 1 — Artifact Registries Research

## 1.1 Official services & quick facts

### AWS
- **Amazon Elastic Container Registry (ECR):** Managed registry for Docker and OCI artifacts, including Helm chart storage through OCI support. Provides vulnerability scanning via Amazon Inspector (basic or enhanced), lifecycle policies, cross-region replication patterns, and pull-through cache for public registries. Charges for stored GB, data transfer out, and optional Inspector scanning.
- **AWS CodeArtifact:** Separate managed package repository for npm, Maven, PyPI, NuGet, and Cargo. Supports upstream proxies to public registries, fine-grained IAM policies, and pay-per-GB storage plus request and egress costs.

### Google Cloud
- **Artifact Registry:** Unified registry that handles Docker/OCI images, Helm charts, Maven, npm, Python, Go modules, Debian (apt), RPM (yum), and generic artifacts. Integrates with Cloud Build, GKE, Cloud Run, and third-party CI. Offers on-demand or continuous vulnerability analysis, regional and virtual repositories, and pricing based on stored GB, network egress, and optional scanning.

### Azure
- **Azure Container Registry (ACR):** Docker/OCI registry with SKUs (Basic, Standard, Premium). Premium adds geo-replication, private endpoints, and higher throughput. Ties into Azure Kubernetes Service, Container Apps, GitHub Actions, and Entra ID/managed identities. Pricing includes tier fees, storage, data transfer, and optional Defender for Containers scanning.
- **Azure Artifacts:** Azure DevOps service for npm, Maven, NuGet, Python, Cargo, and Universal Packages. Supports upstream sources, feed permissions, and offers a free storage allowance before per-GB billing.

## 1.2 Supported artifact types

| Cloud | Service | Containers (OCI/Docker) | Helm (OCI) | Java/Maven | npm | Python | NuGet | Go | OS packages (apt/yum) | Generic |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AWS | ECR | Yes | Yes | No | No | No | No | No | No | Yes (OCI artifacts) |
| AWS | CodeArtifact | No | No | Yes | Yes | Yes | Yes | Yes (Cargo) | No | No |
| Google Cloud | Artifact Registry | Yes | Yes | Yes | Yes | Yes | No | Yes | Yes | Yes |
| Azure | ACR | Yes | Yes | No | No | No | No | No | No | No |
| Azure | Azure Artifacts | No | No | Yes | Yes | Yes | Yes | Yes (Cargo) | No | Yes (Universal) |

## 1.3 Key features, integrations, and pricing notes

- **Security scanning**
  - ECR runs basic or enhanced Amazon Inspector scans against container images.
  - Artifact Registry hooks into Artifact Analysis for automatic or manual vulnerability reports.
  - ACR integrates with Microsoft Defender for Cloud to scan registries and running workloads.
- **Ecosystem integrations**
  - ECR works natively with ECS, EKS, CodeBuild, and IAM roles.
  - Artifact Registry connects with Cloud Build pipelines, GKE deployment hooks, Cloud Run, and Compute Engine.
  - ACR ties into AKS, Container Apps, DevOps pipelines, and supports Azure AD-based auth.
- **Geo and replication**
  - ECR offers multi-account replication, cross-region replication rules, and pull-through cache from public registries.
  - Artifact Registry uses regional repositories with optional remote or virtual repositories for multi-region teams.
  - ACR Premium enables geo-replication and private endpoints with per-replica charges.
- **Pricing patterns**
  - ECR: per-GB storage plus data transfer out, with Inspector scanning and replication incurring extra costs.
  - Artifact Registry: per-GB storage with regional rates, network egress, and optional scanning fees.
  - ACR: tiered pricing (Basic/Standard/Premium) that bundles certain limits; storage and geo-replication billed separately. Azure Artifacts and CodeArtifact add per-GB storage plus request-based pricing after free quotas.

## 1.4 Multi-cloud pick

For a cloud-native registry that already spans many artifact formats, I would pick Google Artifact Registry. It covers container, language, and OS packages in one service, has straightforward integration with Cloud Build/GKE/Cloud Run, and keeps vulnerability analysis in the same workflow. For a broader multi-cloud footprint beyond a single vendor, I would still evaluate neutral registries like Artifactory or Harbor to avoid provider lock-in.

---

# Task 2 — Serverless Computing Platform Research

## 2.1 Official services and execution models

| Cloud | Service(s) | Execution model | Cold-start mitigations | Max HTTP duration | Pricing basics |
| --- | --- | --- | --- | --- | --- |
| AWS | Lambda (+ API Gateway) | Functions packaged as ZIP or OCI images; event-driven and HTTP via API Gateway | Provisioned Concurrency and Lambda SnapStart keep environments warm | 15 minutes | Requests plus GB-seconds; Provisioned Concurrency billed separately |
| Google Cloud | Cloud Functions (2nd gen) on Cloud Run | Functions run on Cloud Run infrastructure; supports HTTP and Eventarc triggers | Minimum instances and adjustable concurrency reduce cold starts | 60 minutes for HTTP; shorter for direct events | vCPU-seconds, GiB-seconds, and request count with a free tier |
| Azure | Azure Functions (Consumption, Premium, Flex) and Container Apps | Functions or serverless containers with HTTP/event triggers | Always-ready instances on Premium/Flex and pre-warmed containers | 10 minutes on Consumption; longer limits on Premium/Flex and Container Apps | Execution count plus GB-seconds; Container Apps bills per vCPU/RAM active time |

## 2.2 Runtimes and performance highlights

- **Lambda:** Supports Node.js, Python, Java, .NET, Ruby, Go, and custom runtimes, with one request processed per execution environment. SnapStart (for Java) and Provisioned Concurrency target latency-sensitive workloads.
- **Cloud Functions (2nd gen):** Runs on Cloud Run with runtimes such as Node.js, Python, Go, Java, .NET, PHP, and Ruby. Concurrency per instance is configurable (up to 1,000) to handle HTTP bursts.
- **Azure Functions:** Offers JavaScript/TypeScript, C#/F#, Python, Java, PowerShell, and custom handlers. Premium and Flex plans pre-warm workers and allow VNet integration, while Container Apps support higher concurrency for containerized workloads.

## 2.3 Condensed comparison

| Aspect | AWS Lambda | Google Cloud Run functions | Azure Functions / Container Apps |
| --- | --- | --- | --- |
| Triggers | Large catalog (S3, SQS, SNS, EventBridge, DynamoDB, etc.) | Native HTTP; Eventarc and Pub/Sub cover many event sources | HTTP, timers, Service Bus, Event Grid, Storage, and custom events |
| HTTP timeouts | 15 minutes max | 60 minutes on HTTP services | 5–10 minutes on Consumption; higher on Premium/Flex and Container Apps |
| Cold-start controls | Provisioned Concurrency and SnapStart | Minimum instances, concurrency knob, and CPU boost on startup | Always-ready instances and scale rules; Container Apps scale-to-zero |
| Packaging | ZIP archive or OCI image | Function source or container | Code packages or container images |
| Observability | CloudWatch Logs, X-Ray, Lambda Insights | Cloud Logging, Cloud Trace, Cloud Monitoring | Application Insights, Log Analytics, Azure Monitor |

## 2.4 Preferred platform for a REST API backend

I lean toward Google Cloud Run for a REST API. It accepts standard containers or functions, allows high concurrency per instance, has the longest HTTP timeout, and lets me keep a warm instance running to smooth out latency. Lambda with API Gateway is still a strong choice when already invested in AWS tooling, especially with Provisioned Concurrency. On Azure, Functions Premium or Container Apps makes sense when tight integration with Azure resources and VNet networking is required.

## 2.5 Reflection on serverless

- **Advantages:** Eliminates server patching, scales automatically, bills in fine-grained increments, and hooks deeply into each cloud’s event ecosystem.
- **Disadvantages:** Cold-start delays, execution time limits, provider-specific quotas, and the risk of lock-in tied to proprietary triggers and monitoring.
