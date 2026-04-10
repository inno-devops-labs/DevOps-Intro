# Lab 10 

## Task 1 - Artifact Registries Research

### Services by Cloud Provider

| Cloud provider | Primary artifact registry service | Official docs |
| --- | --- | --- |
| AWS | Amazon Elastic Container Registry (Amazon ECR) | https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html |
| GCP | Artifact Registry | https://cloud.google.com/artifact-registry/docs |
| Azure | Azure Container Registry (ACR) | https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro |

### Supported Artifact Types

| Provider | Supported artifact types |
| --- | --- |
| AWS ECR | Container images adhering to Docker and OCI specifications, along with compatible artifact formats |
| GCP Artifact Registry | A broad spectrum including container formats (Docker, OCI), Helm charts (OCI mode), language-specific packages (Maven, npm, Python, Go), OS-level packages (Apt, Yum), Kubeflow templates, and unstructured generic files |
| Azure Container Registry | Standard container image formats (Docker, OCI), Helm chart storage, and OCI-based supply chain artifacts |

### Key Features

| Provider | Key features |
| --- | --- |
| AWS ECR | Management of both private and public visibility scopes; fine-grained repository access policies aligned with IAM; automated image scanning for software vulnerabilities; cross-region and cross-account replication strategies; upstream caching via pull-through rules |
| GCP Artifact Registry | Unified interface for multiple package formats; location flexibility with regional or multi-regional storage options; access governance via IAM permissions; integrated security scanning; support for standard, remote proxy, and virtual aggregation repository topologies |
| Azure Container Registry | Geographic distribution via geo-replication; identity and access management integrated with Microsoft Entra ID and RBAC structures; OCI artifact nativity; optimized for proximity deployment within Azure regions; automated build and update mechanisms through ACR Tasks |

### Integration Capabilities

| Provider | Integration highlights |
| --- | --- |
| AWS ECR | Seamless workflow with ECS, EKS, Lambda (container packaging), IAM policies, event routing via EventBridge, and enhanced scanning through Amazon Inspector |
| GCP Artifact Registry | Tight coupling with Cloud Run, GKE, Compute Engine instances, build pipelines in Cloud Build, and the Artifact Analysis security suite |
| Azure Container Registry | Direct integration with AKS, Azure Red Hat OpenShift, App Service deployments, Azure Machine Learning environments, Azure Batch processing, and Microsoft Entra ID governance |

### Pricing Model Basics

| Provider | Pricing basics |
| --- | --- |
| AWS ECR | Consumption-based billing focused on total stored volume and network egress; private repositories include an initial free allocation for new accounts; public repositories maintain a perpetual free usage allowance |
| GCP Artifact Registry | Metered costs associated with bytes stored, network data transfer, and optional vulnerability scanning services; a complementary tier grants up to 0.5 GB of storage at no charge |
| Azure Container Registry | Tiered structure determined by SKU selection (Basic through Premium), with additive costs for storage usage and premium features such as geo-distribution; Premium SKU unlocks enterprise redundancy capabilities |

### Common Use Cases

| Provider | Common use cases |
| --- | --- |
| AWS ECR | Establishing a secure, private image repository for container orchestration on ECS/EKS; proxying and caching public base images; storing runtime artifacts geographically adjacent to AWS compute services |
| GCP Artifact Registry | Serving as a centralized hub for both containerized applications and language-specific dependencies across Cloud Run deployments, GKE clusters, and CI/CD workflows |
| Azure Container Registry | Supporting globally distributed container delivery pipelines; storing OCI-compliant artifacts; enabling Azure-centric deployment automations |

### Registry Comparison

| Factor | AWS ECR | GCP Artifact Registry | Azure Container Registry |
| --- | --- | --- | --- |
| Main focus | Container and OCI artifact management | Multi-format, universal artifact curation | Container and OCI artifact management |
| Broad package support | Limited scope | Most comprehensive among compared services | Limited scope |
| Security controls | IAM alignment, resource-based policies, vulnerability insights | IAM integration, Artifact Analysis, scan capabilities | Entra ID integration, RBAC, virtual network restrictions |
| Replication | Cross-region and cross-account boundaries | Regional and multi-regional data placement | Premium tier geo-replication |
| Ecosystem fit | Optimized for AWS-native orchestration stacks | Ideal for environments mixing container and package workflows | Optimized for Azure container hosting platforms |
| Multi-cloud friendliness | Suitable for OCI standard artifacts | Highest flexibility for heterogeneous artifact types | Strong performance for OCI-focused distribution |

### Analysis

When evaluating a multi-cloud architectural posture, **GCP Artifact Registry** presents the most compelling reference model. The distinct advantage lies in its breadth of format accommodation; unlike its competitors which focus predominantly on container runtimes, Artifact Registry collapses the distinction between image storage and language-specific package hosting (Maven, npm, Python, Go, etc.). This consolidation simplifies the governance and distribution logic for teams operating across diverse runtime environments. While ECR and ACR exhibit robust performance within their respective native ecosystems, Artifact Registry offers superior adaptability for a strategy that spans multiple cloud vendors and mixed application dependencies.

## Task 2 - Serverless Computing Platform Research

### Services by Cloud Provider

| Cloud provider | Primary serverless compute service(s) | Official docs |
| --- | --- | --- |
| AWS | AWS Lambda | https://aws.amazon.com/documentation-overview/lambda/ |
| GCP | Cloud Run | https://cloud.google.com/run/docs/overview/what-is-cloud-run |
| Azure | Azure Functions | https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview |

### Key Features and Capabilities

| Provider | Key features |
| --- | --- |
| AWS Lambda | Execution driven by service events; extensive catalog of native AWS event sources; managed runtime environments; elastic scaling without user intervention; deployment flexibility via archive packages or container images |
| GCP Cloud Run | Abstraction layer for serverless containers; natively exposes secure HTTPS endpoints; dynamic scaling including full scale-to-zero capability; invocation via HTTP protocol or asynchronous events; support for source-based or container-based deployment |
| Azure Functions | Event-centric compute model; comprehensive binding system for input/output data flow; triggers for HTTP requests, timer schedules, and queue processing; multiple hosting infrastructure options |

### Supported Runtimes and Languages

| Provider | Runtime / language model |
| --- | --- |
| AWS Lambda | Pre-configured execution environments for major language families (Python, Node.js, Java, .NET, Ruby) supplemented by custom runtime API support for unsupported languages |
| GCP Cloud Run | Complete language agnosticism when utilizing container packaging; source deployment wizards provide optimized experiences for Go, Node.js, Python, Java, .NET, and Ruby frameworks |
| Azure Functions | First-class support for C#, Java, JavaScript, PowerShell, and Python; extension points available via custom handlers and containerized deployment for other stacks |

### Execution Models

| Provider | Execution model |
| --- | --- |
| AWS Lambda | Event-driven architecture; invocation occurs via direct API calls or event source polling against streaming/queueing services |
| GCP Cloud Run | Primary interface is HTTP request handling; event-driven behavior extended through Eventarc integration with the broader Google Cloud event fabric |
| Azure Functions | Trigger and binding paradigm; execution initiated by defined events including HTTP endpoints, timers, storage operations, message queues, and database updates |

### Pricing Comparison

| Provider | Pricing model |
| --- | --- |
| AWS Lambda | Billing dimensions include total invocation count and compute duration measured in GB-seconds; generous free allocation covering 1M requests and 400,000 GB-seconds monthly |
| GCP Cloud Run | Granular billing for allocated vCPU, memory, and request handling with 100ms resolution; monthly free allowance includes compute seconds and 2M requests |
| Azure Functions | Consumption and Flex plans meter based on execution count and resource utilization; platform advertises complimentary monthly grant of executions and consumption-based billing |

### Performance and Scaling Characteristics

| Provider | Cold start / scaling characteristics | Max execution duration |
| --- | --- | --- |
| AWS Lambda | Initialization latency correlates with deployment artifact size and runtime selection; interpreted languages typically exhibit faster startup than JIT-compiled alternatives | 900 seconds (15 minutes) |
| GCP Cloud Run | Request concurrency scaling; idle instances incur zero cost; cold start latency can be mitigated using "minimum instances" configuration | Default 300 seconds, configurable up to 3600 seconds (60 minutes) |
| Azure Functions | Startup behavior is contingent on the selected hosting tier; Flex Consumption plan introduces pre-warmed instances to reduce initialization penalty | Variable based on hosting plan and specific trigger configuration |

### Integration Capabilities

| Provider | Integration highlights |
| --- | --- |
| AWS Lambda | Extensive connectivity with API Gateway, S3 object events, DynamoDB streams, EventBridge, SNS topics, SQS queues, Step Functions workflows, and Kinesis data streams |
| GCP Cloud Run | Native HTTPS endpoints; event consumption via Eventarc; secure service-to-service authentication through IAM across the Google Cloud environment |
| Azure Functions | HTTP endpoint exposure; bindings to storage blob events, queue messages, timer schedules, Cosmos DB change feeds, Event Hubs, Service Bus, and stateful Durable Functions patterns |

### Serverless Platform Comparison

| Factor | AWS Lambda | GCP Cloud Run | Azure Functions |
| --- | --- | --- | --- |
| Best abstraction | Function-centric logic unit | Container-centric application instance | Function-centric logic unit |
| HTTP API fit | Robust when paired with API Gateway | Excellent; HTTP is the foundational interaction model | Robust via HTTP trigger binding |
| Event ecosystem | Highly mature and dense within AWS | Capable via Eventarc and Google service integration | Highly mature via trigger and binding catalog |
| Runtime flexibility | Good | Superior; container runtime allows arbitrary binaries and language stacks | Good, particularly for common event processing tasks |
| Timeout flexibility | Capped at 15 minutes | Extensible up to 60 minutes | Dependent on selected service tier |
| Cold-start mitigation | Provisioned concurrency available | Minimum instance count available | Flex Consumption tier offers pre-warmed capacity |

### Analysis

For the purpose of implementing a **REST API backend**, the selection leans toward **GCP Cloud Run**. The platform's design philosophy centers on HTTP as a primary transport rather than an adapter layer. Each deployment receives a managed, secure URL endpoint, supports granular scale-to-zero economics, and imposes a more generous execution timeout ceiling (up to 60 minutes) compared to Lambda. This approach grants development teams the autonomy to select any runtime or framework via container packaging. While AWS Lambda excels in event-sourcing patterns and Azure Functions provides superior binding logic, Cloud Run minimizes friction for standard web API delivery.

### Reflection

Serverless adoption confers significant operational advantages, including the abstraction of underlying infrastructure maintenance, automated elasticity in response to load fluctuations, and a consumption-based billing model that aligns cost directly with usage. Development velocity increases as concerns around host patching, scaling thresholds, and capacity forecasting are shifted to the provider.

Conversely, drawbacks include the presence of cold start latency penalties, increased architectural dependency on a specific cloud vendor's proprietary services, bounded execution time constraints, and challenges associated with local debugging fidelity compared to traditional persistent server environments. Cost predictability can erode under sustained high traffic or long-running process scenarios. Serverless architectures demonstrate optimal efficacy for intermittent workloads, event processing pipelines, APIs with variable traffic patterns, and scenarios where reduced management burden outweighs the need for granular infrastructure tuning.

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
