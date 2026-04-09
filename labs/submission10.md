# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Services by Cloud Provider

| Cloud provider | Primary artifact registry service | Official docs |
| --- | --- | --- |
| AWS | Amazon Elastic Container Registry (Amazon ECR) | https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html |
| GCP | Artifact Registry | https://cloud.google.com/artifact-registry/docs |
| Azure | Azure Container Registry (ACR) | https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro |

### Supported Artifact Types

| Provider | Supported artifact types |
| --- | --- |
| AWS ECR | Docker images, OCI images, and OCI-compatible artifacts |
| GCP Artifact Registry | Docker images, OCI images, Helm charts packaged as OCI, Maven, npm, Python, Apt, Yum, Go, Kubeflow pipeline templates, and generic artifacts |
| Azure Container Registry | Docker images, OCI images, Helm charts, OCI artifacts, and supply-chain related OCI artifacts |

### Key Features

| Provider | Key features |
| --- | --- |
| AWS ECR | Private/public registries, repository policies and IAM integration, vulnerability scanning, cross-Region and cross-account replication, pull-through cache |
| GCP Artifact Registry | Multi-format repositories, regional and multi-regional storage, IAM-based access control, vulnerability scanning support, standard/remote/virtual repository patterns |
| Azure Container Registry | Geo-replication, Microsoft Entra ID and RBAC integration, OCI artifact support, network-close deployment, automated build/patch workflows with ACR Tasks |

### Integration Capabilities

| Provider | Integration highlights |
| --- | --- |
| AWS ECR | Integrates naturally with ECS, EKS, Lambda container images, IAM, EventBridge, and Amazon Inspector-enhanced scanning |
| GCP Artifact Registry | Integrates with Cloud Run, GKE, Compute Engine, Cloud Build, and Artifact Analysis |
| Azure Container Registry | Integrates with AKS, Azure Red Hat OpenShift, App Service, Azure Machine Learning, Azure Batch, and Microsoft Entra ID |

### Pricing Model Basics

| Provider | Pricing basics |
| --- | --- |
| AWS ECR | Pay for stored data and data transfer; private repo storage has a free tier for new customers and public repos have an always-free allowance |
| GCP Artifact Registry | Pay for storage, data transfer, and vulnerability scanning where enabled; free tier includes up to 0.5 GB storage |
| Azure Container Registry | Tier-based pricing by SKU plus storage and premium capabilities such as geo-replication; Premium adds enterprise features |

### Common Use Cases

| Provider | Common use cases |
| --- | --- |
| AWS ECR | Private container registry for ECS/EKS, caching upstream public images, storing OCI artifacts close to AWS runtime environments |
| GCP Artifact Registry | Central package and image repository for container and language-package workflows across Cloud Run, GKE, and build pipelines |
| Azure Container Registry | Enterprise registry for global container delivery, OCI artifact storage, and Azure-centered deployment pipelines |

### Registry Comparison

| Factor | AWS ECR | GCP Artifact Registry | Azure Container Registry |
| --- | --- | --- | --- |
| Main focus | Container/OCI registry | Universal artifact registry | Container/OCI registry |
| Broad package support | Moderate | Strongest of the three | Moderate |
| Security controls | IAM, repo policies, scanning | IAM, Artifact Analysis, scanning | Entra ID, RBAC, network controls |
| Replication | Cross-Region and cross-account | Regional/multi-regional placement | Geo-replication in Premium |
| Ecosystem fit | Best in AWS-native stacks | Best when mixing containers and language packages | Best in Azure container platforms |
| Multi-cloud friendliness | Good for OCI artifacts | Best for mixed artifact formats | Strong for OCI-centric delivery |

### Analysis

For a multi-cloud strategy, I would choose **GCP Artifact Registry** as the primary design reference. The main reason is that it is the broadest artifact service in this comparison: it supports not only container images and OCI artifacts, but also Maven, npm, Python, Apt, Yum, Go, generic artifacts, and Kubeflow templates in one product. That makes it easier to standardize how teams publish and consume artifacts across heterogeneous environments. AWS ECR and Azure Container Registry are very strong when the workload is mostly container-focused, but Artifact Registry is more flexible when a multi-cloud strategy includes both containers and application package ecosystems.

## Task 2 — Serverless Computing Platform Research

### Services by Cloud Provider

| Cloud provider | Primary serverless compute service(s) | Official docs |
| --- | --- | --- |
| AWS | AWS Lambda | https://aws.amazon.com/documentation-overview/lambda/ |
| GCP | Cloud Run | https://cloud.google.com/run/docs/overview/what-is-cloud-run |
| Azure | Azure Functions | https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview |

### Key Features and Capabilities

| Provider | Key features |
| --- | --- |
| AWS Lambda | Event-driven execution, many AWS event sources, managed runtimes, automatic scaling, ZIP or container deployment |
| GCP Cloud Run | Fully managed serverless containers, HTTPS-native services, scale to zero, HTTP and event-driven invocation, source or container deployment |
| Azure Functions | Event-driven functions, rich triggers and bindings, HTTP APIs, scheduling, queue and data event processing, multiple hosting options |

### Supported Runtimes and Languages

| Provider | Runtime / language model |
| --- | --- |
| AWS Lambda | Managed runtimes for multiple language families plus custom runtimes; official docs emphasize Python, Node.js, Java, .NET, Ruby and custom runtime support |
| GCP Cloud Run | Any language if packaged as a container; source-based deployment supports Go, Node.js, Python, Java, .NET, Ruby, and supported frameworks |
| Azure Functions | Native support for C#, Java, JavaScript, PowerShell, Python, plus additional languages through custom handlers and containers |

### Execution Models

| Provider | Execution model |
| --- | --- |
| AWS Lambda | Event-driven; direct invocation and event source mappings for streams and queues |
| GCP Cloud Run | HTTP-triggered services plus event-driven services through Eventarc |
| Azure Functions | Event-driven triggers and bindings, including HTTP, timers, queues, blobs, databases, service bus, and more |

### Pricing Comparison

| Provider | Pricing model |
| --- | --- |
| AWS Lambda | Charged by requests and execution duration; free tier includes 1 million requests and 400,000 GB-seconds per month |
| GCP Cloud Run | Charged for CPU, memory, and requests based on actual use with 100 ms granularity; free tier includes vCPU-seconds, GiB-seconds, and 2 million requests |
| Azure Functions | Flex Consumption and related serverless plans charge by executions and active resource usage; Azure highlights free monthly executions and execution-based billing |

### Performance and Scaling Characteristics

| Provider | Cold start / scaling characteristics | Max execution duration |
| --- | --- | --- |
| AWS Lambda | Cold starts depend on runtime and initialization size; interpreted runtimes tend to start faster, compiled runtimes often initialize slower | 900 seconds (15 minutes) |
| GCP Cloud Run | Cold starts occur when scaling from zero; minimum instances can reduce cold starts; request-based autoscaling is fast and HTTP-native | Default 300 seconds, up to 3600 seconds (60 minutes) |
| Azure Functions | Cold starts depend heavily on hosting plan; Flex Consumption improves cold-start behavior with always-ready instances | Depends on hosting option; Azure Functions hosting plans vary by plan and execution mode |

### Integration Capabilities

| Provider | Integration highlights |
| --- | --- |
| AWS Lambda | API Gateway, S3, DynamoDB, EventBridge, SNS, SQS, Step Functions, Kinesis, MSK, and many other AWS services |
| GCP Cloud Run | HTTPS endpoints, Eventarc, Artifact Registry, Cloud Build, IAM, and service-to-service auth across Google Cloud |
| Azure Functions | HTTP triggers, storage events, queues, timers, Cosmos DB, Event Hubs, Service Bus, Durable Functions, and bindings to many Azure services |

### Serverless Platform Comparison

| Factor | AWS Lambda | GCP Cloud Run | Azure Functions |
| --- | --- | --- | --- |
| Best abstraction | Function-first | Container-first serverless | Function-first |
| HTTP API fit | Strong with API Gateway | Excellent, built around HTTPS services | Strong with HTTP triggers |
| Event ecosystem | Very strong in AWS | Strong via Eventarc and Google services | Very strong via triggers/bindings |
| Runtime flexibility | Good | Best, because containers allow almost any language | Good, especially for event-driven apps |
| Timeout flexibility | 15 minutes max | Up to 60 minutes | Plan-dependent |
| Cold-start mitigation | Provisioned options available | Minimum instances available | Flex Consumption always-ready instances |

### Analysis

For a **REST API backend**, I would choose **GCP Cloud Run**. Its main strength is that HTTP is the native operating model, not an add-on. Each service gets a managed HTTPS endpoint, scales to zero when idle, and can be deployed from a container or directly from source. It is also more flexible for teams that want custom runtimes, framework freedom, or longer-running request handling than Lambda’s 15-minute limit. AWS Lambda is excellent for event-heavy architectures, and Azure Functions is strong for trigger-and-binding scenarios, but Cloud Run is the simplest fit for a straightforward REST backend.

### Reflection

The main advantages of serverless computing are lower operational overhead, automatic scaling, faster iteration, and pay-for-use billing. Teams can focus on application behavior instead of VM management, patching, or manual capacity planning. Serverless also makes it easy to connect applications to cloud-native events and services.

The main disadvantages are cold starts, tighter coupling to provider-specific services, execution limits, and more complex debugging or local emulation compared with traditional long-running services. Cost can also become harder to predict at scale when request volume is high or workloads remain active for long periods. In practice, serverless is strongest for bursty workloads, event processing, APIs with variable demand, and systems where operational simplicity matters more than low-level infrastructure control.

## Sources

### Artifact registries

1. AWS ECR private repositories: https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html
2. AWS ECR image scanning: https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html
3. AWS ECR replication: https://docs.aws.amazon.com/AmazonECR/latest/userguide/replication.html
4. AWS ECR pull-through cache: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
5. AWS ECR pricing: https://aws.amazon.com/ecr/pricing/
6. GCP Artifact Registry docs: https://cloud.google.com/artifact-registry/docs
7. GCP Artifact Registry supported formats: https://cloud.google.com/artifact-registry/docs/supported-formats
8. GCP Artifact Registry pricing: https://cloud.google.com/artifact-registry/pricing
9. Azure Container Registry intro: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro
10. Azure Container Registry concepts: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-concepts
11. Azure Container Registry geo-replication: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-geo-replication
12. Azure Container Registry pricing: https://azure.microsoft.com/en-us/pricing/details/container-registry

### Serverless platforms

1. AWS Lambda docs overview: https://aws.amazon.com/documentation-overview/lambda/
2. AWS Lambda runtimes: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
3. AWS Lambda timeout: https://docs.aws.amazon.com/lambda/latest/dg/configuration-timeout.html
4. AWS Lambda pricing: https://aws.amazon.com/lambda/pricing/
5. AWS Lambda event-driven architectures: https://docs.aws.amazon.com/lambda/latest/dg/concepts-event-driven-architectures.html
6. GCP Cloud Run overview: https://cloud.google.com/run/docs/overview/what-is-cloud-run
7. GCP Cloud Run pricing: https://cloud.google.com/run/pricing
8. GCP Cloud Run request timeout: https://cloud.google.com/run/docs/configuring/request-timeout
9. GCP Cloud Run HTTPS invocation: https://cloud.google.com/run/docs/triggering/https-request
10. GCP Cloud Run Eventarc triggers: https://cloud.google.com/run/docs/triggering/trigger-with-events
11. Azure Functions overview: https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview
12. Azure Functions supported languages: https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages
13. Azure Functions triggers and bindings: https://learn.microsoft.com/en-us/azure/azure-functions/functions-triggers-bindings
14. Azure Functions hosting options: https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale
15. Azure Functions pricing: https://azure.microsoft.com/en-us/pricing/details/functions/
