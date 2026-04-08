# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

Artifact registries store container images and build artifacts for CI/CD workflows.

### AWS: Amazon ECR

Amazon Elastic Container Registry is AWS’s managed container registry. It supports Docker and OCI images, uses IAM for access control, and integrates with ECS, EKS, and Lambda.

Key points:
- Private and public image repositories.
- Image scanning, lifecycle policies, replication.
- Pricing is based on storage and data transfer.

### GCP: Artifact Registry

Google Artifact Registry is GCP’s main artifact service. It supports container images and package formats like npm, Maven, and Python.

Key points:
- IAM-based access control.
- Integrates with Cloud Build, Cloud Run, and GKE.
- Pricing is storage-based with a free tier.

### Azure: Azure Container Registry

Azure Container Registry is Microsoft’s private container registry. It supports container images and OCI artifacts.

Key points:
- Integrates with Microsoft Entra ID.
- Offers Basic, Standard, and Premium tiers.
- Premium includes geo-replication.

### Registry Comparison

| Provider | Service | Artifact types | Access control | Replication | Pricing |
|---|---|---|---|---|---|
| AWS | Amazon ECR | Docker, OCI images | IAM | Cross-region | Storage and transfer |
| GCP | Artifact Registry | Images, package formats | IAM | Multi-region options | Storage-based |
| Azure | ACR | Images, OCI artifacts | Entra ID | Geo-replication | Tier-based |

### Multi-cloud choice

I would choose Google Artifact Registry for multi-cloud use because it supports both container images and package formats in one service.

## Task 2 — Serverless Computing Research

Serverless platforms let you run code without managing servers.

### AWS: Lambda

AWS Lambda is AWS’s main serverless service. It supports event-driven execution, HTTP APIs, and many AWS integrations.

Key points:
- Supports many runtimes and container images.
- Pricing is based on requests and execution time.
- Maximum execution time is 15 minutes.

### GCP: Cloud Run functions / Cloud Functions

Google Cloud’s serverless platform supports HTTP and event-driven functions.

Key points:
- Integrates with Cloud Run, Eventarc, and Cloud Build.
- Supports common languages like Node.js, Python, Go, and Java.
- Pricing is based on invocations and runtime usage.

### Azure: Azure Functions

Azure Functions is Microsoft’s serverless platform. It supports HTTP triggers, queue triggers, timers, and event-driven workloads.

Key points:
- Supports several languages including C#, JavaScript, Python, and Java.
- Consumption plan charges per execution and time.
- Max duration is 10 minutes on Consumption.

### Serverless Comparison

| Provider | Service | Triggers | Pricing | Max duration |
|---|---|---|---|---|
| AWS | Lambda | Event-driven, HTTP, async | Requests + duration | 15 minutes |
| GCP | Cloud Run functions | HTTP, events | Invocations + usage | Up to 60 minutes for some functions |
| Azure | Azure Functions | HTTP, queues, timers, events | Per execution + time | 10 minutes on Consumption |

### REST API choice

I would choose AWS Lambda for a REST API backend because it integrates well with API Gateway and scales easily.

### Serverless reflection

Serverless is good because it reduces server management, scales automatically, and can be cost-effective. The downsides are cold starts, execution limits, and vendor lock-in.

## Conclusion

AWS ECR, Google Artifact Registry, and Azure Container Registry are the main registry services. AWS Lambda, GCP serverless functions, and Azure Functions are the main serverless options. Each provider is strongest in its own ecosystem.
