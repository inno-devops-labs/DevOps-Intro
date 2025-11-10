# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Overview

Artifact registries are central components of modern DevOps pipelines, enabling teams to store, manage, version, and distribute container images, packages, and build artifacts securely across environments. This research compares the primary artifact registry services from AWS, GCP, and Azure.

### 1.1 Individual Service Research

#### AWS — Amazon Elastic Container Registry (ECR)

**Service Name:** Amazon Elastic Container Registry (ECR)

**Official Documentation:** https://docs.aws.amazon.com/ecr/

**Key Features:**
- Native AWS integration with ECS, EKS, and Lambda
- Automatic encryption at rest and in transit using AWS KMS
- Image vulnerability scanning with Amazon Inspector
- Lifecycle policies for automated image cleanup
- Cross-region replication for disaster recovery and global distribution
- Private repositories by default with fine-grained IAM access control
- Cost-optimized with no data transfer fees between ECR and EC2
- Integration with AWS CodePipeline and CodeBuild

**Supported Artifact Types:**
- Container images (Docker, OCI format)
- Helm charts
- Amazon Machine Images (AMIs)

**Integration Capabilities:**
- ECS task definitions
- EKS for Kubernetes deployments
- Lambda for container images
- AWS CodePipeline for CI/CD workflows
- IAM for access control
- CloudWatch for monitoring and logging
- EventBridge for event-driven actions

**Pricing Model:**
- Storage: $0.10 per GB-month
- Data transfer out: $0.02 per GB (to internet), free within AWS services in same region
- Image scans: Free with basic features, enhanced scanning available

**Common Use Cases:**
- Container image storage for containerized applications
- Integration with microservices architectures on ECS/EKS
- Private image distribution for enterprise applications
- Cross-account image sharing via cross-account ECR access

---

#### GCP — Artifact Registry

**Service Name:** Artifact Registry

**Official Documentation:** https://cloud.google.com/artifact-registry/docs

**Key Features:**
- Multi-format support (containers, Maven, npm, Python, Gradle, etc.)
- Binary authorization with enforced image signatures
- Vulnerability scanning with Container Analysis
- Granular IAM-based access control
- High availability and automatic replication
- Support for regional and multi-region repositories
- Workload Identity integration for secure authentication
- Fine-grained permissions and organizational policies

**Supported Artifact Types:**
- Container images (Docker, OCI format)
- Python packages (PyPI)
- npm packages
- Maven packages
- Gradle packages
- Generic artifacts
- Helm charts (stored as OCI images)

**Integration Capabilities:**
- Google Cloud Build for automated builds
- Google Kubernetes Engine (GKE) for deployments
- Cloud Run for serverless container deployments
- Binary Authorization for security policy enforcement
- Identity and Access Management (IAM)
- Cloud Monitoring and Logging
- Pub/Sub for event notifications

**Pricing Model:**
- Storage: $0.10 per GB-month
- Data transfer out: $0.12 per GB (to internet), free within Google Cloud
- Vulnerability scanning: $0.26 per image scanned per month

**Common Use Cases:**
- Multi-format artifact storage for diverse development teams
- Polyglot development environments (different languages and package managers)
- Integration with Cloud Build and Cloud Run pipelines
- Enterprise security with binary authorization requirements

---

#### Azure — Azure Container Registry (ACR)

**Service Name:** Azure Container Registry (ACR)

**Official Documentation:** https://docs.microsoft.com/en-us/azure/container-registry/

**Key Features:**
- Multi-tier support (Basic, Standard, Premium)
- Geo-replication for global distribution
- Azure role-based access control (RBAC) integration
- Content trust with Docker Content Trust
- Webhook support for CI/CD triggers
- Task scheduler for automated builds and pushes
- Quarantine pattern for image validation before release
- Private endpoint support for network isolation

**Supported Artifact Types:**
- Container images (Docker, OCI format)
- Helm charts
- OCI artifacts
- OCI image index
- Generic artifacts

**Integration Capabilities:**
- Azure Container Instances (ACI) for serverless container execution
- Azure Kubernetes Service (AKS) for Kubernetes workloads
- Azure DevOps Pipelines for CI/CD automation
- Azure AD/Entra ID for identity and access management
- Azure Monitor for observability
- Event Grid for event-driven integrations
- Azure Policy for compliance enforcement

**Pricing Model:**
- Basic: $5/month (10 GB storage)
- Standard: $50/month (100 GB storage, higher throughput)
- Premium: $250/month (1 TB storage, maximum throughput, geo-replication)
- Storage overage: $0.10 per GB-month

**Common Use Cases:**
- Azure-native container deployments on AKS and ACI
- Enterprise organizations leveraging Azure ecosystem
- Geo-distributed teams requiring multi-region replication
- Organizations requiring compliance with Azure Policy

---

### 1.2 Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| **Primary Formats** | Container images | Multi-format (Docker, Maven, npm, Python, etc.) | Container images, Helm, OCI |
| **Vulnerability Scanning** | ✅ Amazon Inspector | ✅ Container Analysis | ✅ Via Azure Defender |
| **Geo-Replication** | ✅ Cross-region | ✅ Automatic multi-region | ✅ Premium tier |
| **Access Control** | ✅ IAM (fine-grained) | ✅ IAM (fine-grained) | ✅ RBAC (fine-grained) |
| **CI/CD Integration** | CodePipeline, CodeBuild | Cloud Build | Azure DevOps |
| **Serverless Integration** | ✅ Lambda, ECS, EKS | ✅ Cloud Run, GKE | ✅ ACI, AKS |
| **Cost (Storage/GB-month)** | $0.10 | $0.10 | $0.10 (overage) |
| **Data Transfer (out/GB)** | $0.02 (AWS), Free (within AWS) | $0.12 (internet), Free (Google Cloud) | Included in tier pricing |
| **Image Signing** | ✅ Via ECR | ✅ Binary Authorization | ✅ Content Trust |
| **Webhook Support** | ✅ EventBridge | ✅ Pub/Sub | ✅ Native webhooks |
| **Ease of Setup** | Moderate | Moderate | Moderate |

---

### 1.3 Analysis: Multi-Cloud Strategy Recommendation

**For a Multi-Cloud Strategy, I would recommend using GCP Artifact Registry** for the following reasons:

1. **Multi-Format Support:** GCP Artifact Registry supports Docker, Maven, npm, Python, and Gradle packages natively. This makes it superior for organizations with polyglot development environments that span across multiple clouds. AWS ECR and Azure ACR are primarily container-focused.

2. **Cloud-Agnostic Abstraction:** While Artifact Registry is a GCP service, its multi-format support creates a unified artifact management layer that can serve multiple cloud environments more easily than ECR or ACR.

3. **Flexibility:** Organizations can store all artifact types (containers, code packages, binaries) in one system, reducing complexity of multi-registry management.

**However, practical multi-cloud strategies often employ:**

- **Primary registry per cloud:** Use each cloud provider's native registry (ECR for AWS workloads, Artifact Registry for GCP workloads, ACR for Azure workloads) to leverage native integrations and avoid egress costs
- **Central artifact hub:** Implement a central artifact management solution (like JFrog Artifactory or Sonatype Nexus) that syncs with all three cloud registries for true multi-cloud distribution
- **Hybrid approach:** Use each cloud's native registry for performance, with a central repository for archival and cross-cloud distribution

**Recommendation for DevOps teams:** For true multi-cloud deployments, consider JFrog Artifactory or Sonatype Nexus as a central hub that federates with AWS ECR, GCP Artifact Registry, and Azure ACR. This provides vendor independence while leveraging each cloud's native capabilities.

---

## Task 2 — Serverless Computing Platform Research

### Overview

Serverless computing abstracts infrastructure management, allowing developers to focus on code while cloud providers handle scaling, maintenance, and operational overhead. This research compares the primary serverless compute services from AWS, GCP, and Azure.

### 2.1 Individual Service Research

#### AWS — AWS Lambda

**Service Name:** AWS Lambda

**Official Documentation:** https://docs.aws.amazon.com/lambda/

**Key Features:**
- Event-driven architecture support (S3, DynamoDB, SNS, SQS, API Gateway, etc.)
- Sub-second scaling and automatic concurrency management
- Reserved Concurrency for predictable performance
- Provisioned Concurrency to eliminate cold starts
- Layers for code reuse and dependency management
- VPC integration for private network access
- Local debugging with SAM CLI
- X-Ray integration for distributed tracing
- Dead Letter Queues (DLQ) for error handling
- Environment variables and parameter store integration

**Supported Runtimes/Languages:**
- Node.js (18.x, 20.x)
- Python (3.11, 3.12)
- Java (11, 17, 21)
- Go (1.x)
- .NET (.NET 6, 7, 8)
- Ruby (3.2, 3.3)
- Custom runtimes via Lambda Layers

**Execution Models:**
- Event-driven (S3 events, DynamoDB streams, Kinesis, etc.)
- HTTP-triggered via API Gateway
- Scheduled via EventBridge/CloudWatch Events
- Direct invocation via SDK/CLI
- Integration with SNS, SQS, and other AWS services

**Cold Start Performance:**
- Python/Node.js: 100-300ms
- Java: 500-1000ms+ (can be improved with provisioned concurrency)
- Go: 50-150ms (fastest)

**Integration with Other Services:**
- API Gateway for REST/HTTP APIs
- DynamoDB, RDS, ElastiCache for data persistence
- S3 for object storage and triggers
- SNS/SQS for event queuing and distribution
- CloudWatch for logging and monitoring
- IAM for fine-grained access control

**Pricing Model:**
- Request pricing: $0.20 per 1 million requests
- Duration pricing: $0.0000166667 per GB-second (GB allocated × seconds executed)
- Always Free Tier: 1 million requests and 400,000 GB-seconds per month
- Provisioned Concurrency: charged per concurrent execution

**Maximum Execution Duration:** 15 minutes (900 seconds)

**Common Use Cases:**
- REST API backends with API Gateway
- Real-time file processing (S3 triggers)
- Data stream processing (Kinesis, DynamoDB Streams)
- Scheduled tasks and cron jobs
- Microservices architecture
- Event-driven data pipelines
- IoT data ingestion and processing

---

#### GCP — Google Cloud Functions

**Service Name:** Google Cloud Functions

**Official Documentation:** https://cloud.google.com/functions/docs

**Key Features:**
- Multiple trigger types (HTTP, Pub/Sub, Cloud Storage, Cloud Tasks, etc.)
- Automatic scaling from 0 to 1000s of instances
- Integrated with Cloud Logging and Cloud Trace
- Binary Authorization support
- VPC Service Controls for security perimeter
- Memory allocation from 128 MB to 16 GB
- CPU scaling proportional to memory allocation
- Secrets Manager integration
- Source repository integration (Cloud Source Repositories, GitHub)
- Background functions for asynchronous processing

**Supported Runtimes/Languages:**
- Node.js (18, 20, 22)
- Python (3.11, 3.12)
- Go (1.21, 1.22)
- Java (17, 21)
- .NET (.NET 6, 7, 8)
- Ruby (3.2, 3.3)
- PHP (8.2, 8.3)

**Execution Models:**
- HTTP functions (HTTP, Cloud Tasks, Eventarc)
- Background functions (Pub/Sub, Cloud Storage, Firestore, etc.)
- CloudEvents format for standardized events
- Direct invocation via gcloud CLI or SDK

**Cold Start Performance:**
- Python/Node.js: 200-500ms
- Go: 100-300ms
- Java: 800-1500ms+

**Integration with Other Services:**
- Cloud Run for containerized functions
- Pub/Sub for event distribution
- Cloud Storage for file events
- Firestore for database triggers
- Cloud SQL for database operations
- Cloud Logging and Trace for observability
- Eventarc for multi-source event routing
- Cloud Scheduler for scheduled execution

**Pricing Model:**
- Invocations: $0.40 per 1 million invocations
- Compute: $0.0000083333 per GB-second ($0.30 per million GB-seconds)
- Always Free Tier: 2 million invocations and 400,000 GB-seconds per month

**Maximum Execution Duration:** 60 minutes (3,600 seconds)

**Common Use Cases:**
- REST/HTTP API backends
- Real-time data processing from Pub/Sub
- Cloud Storage event handling
- Scheduled jobs via Cloud Scheduler
- Webhook receivers for third-party integrations
- Multi-cloud event orchestration via Eventarc
- Microservices with event-driven architecture

---

#### Azure — Azure Functions

**Service Name:** Azure Functions

**Official Documentation:** https://docs.microsoft.com/en-us/azure/azure-functions/

**Key Features:**
- Multiple hosting plans (Consumption, Premium, Dedicated, Container Instances)
- 200+ binding integrations (no code for common scenarios)
- Durable Functions for complex workflows and orchestration
- Entity Functions for state management
- Activity Functions for sequential workflows
- Support for both stateless and stateful patterns
- Local development with Azure Functions Core Tools
- Integration with Azure DevOps and GitHub Actions
- Built-in monitoring and diagnostics
- VNet integration for private deployments

**Supported Runtimes/Languages:**
- C# (.NET 6, 7, 8)
- Python (3.11, 3.12)
- JavaScript/TypeScript (Node.js 18, 20)
- Java (11, 17, 21)
- PowerShell (7.2, 7.3)
- Custom handlers (any language via HTTP protocol)

**Execution Models:**
- HTTP-triggered (REST APIs)
- Timer-triggered (scheduled)
- Event-triggered (Blob Storage, Event Grid, Event Hubs, Service Bus, etc.)
- Queue-triggered (Queue Storage, Service Bus)
- Durable Functions for orchestration and workflows

**Cold Start Performance:**
- Consumption plan: 2-10 seconds (includes spin-up time)
- Premium plan: 100-500ms (pre-warmed instances)
- Dedicated plan: 50-200ms (continuous runtime)

**Integration with Other Services:**
- Azure Storage (Blob, Queue, Table) via bindings
- Azure Cosmos DB for database operations
- Event Grid for event routing
- Event Hubs for streaming data
- Service Bus for messaging
- Application Insights for monitoring and telemetry
- Azure Logic Apps for workflow orchestration
- Azure DevOps and GitHub for CI/CD

**Pricing Model:**
- **Consumption Plan:** $0.20 per 1 million executions + execution time cost
- **Premium Plan:** Starting ~$0.01459/hour per vCPU allocated, includes monthly grant
- **Dedicated Plan:** App Service plan pricing (flat rate per instance)
- Always Free Tier: 1 million requests + 400,000 GB-seconds per month (consumption plan)

**Maximum Execution Duration:**
- Consumption plan: 10 minutes (600 seconds)
- Premium plan: 60 minutes (3,600 seconds) configurable
- Dedicated plan: Unlimited

**Common Use Cases:**
- Workflow orchestration with Durable Functions
- Real-time data processing from Event Hubs
- Event-driven microservices
- REST API backends
- Webhook handlers and integrations
- Batch processing with timers
- Business process automation
- Integration with Office 365 and Microsoft Teams

---

### 2.2 Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions | Azure Functions |
|---------|------------|----------------------|-----------------|
| **Supported Languages** | 7 (Node, Python, Java, Go, .NET, Ruby, Custom) | 7 (Node, Python, Go, Java, .NET, Ruby, PHP) | 6 (.NET, Python, Node, Java, PowerShell, Custom) |
| **Cold Start (Python/Node)** | 100-300ms | 200-500ms | 2-10s (consumption) |
| **Cold Start (Go)** | 50-150ms | 100-300ms | N/A |
| **Memory Options** | 128 MB - 10 GB | 128 MB - 16 GB | Consumption: Auto; Premium: Configurable |
| **Max Execution Duration** | 15 minutes | 60 minutes | 10 min (consumption), 60 min (premium) |
| **Event Triggers** | 200+ (S3, DynamoDB, SNS, SQS, etc.) | 100+ (Pub/Sub, Storage, Firestore, etc.) | 200+ (storage, Event Grid, Event Hubs, etc.) |
| **HTTP API Support** | ✅ API Gateway | ✅ Native HTTP trigger | ✅ Native HTTP trigger |
| **Orchestration** | Step Functions (separate service) | Workflows API | ✅ Durable Functions (native) |
| **Scaling** | Automatic (0 to thousands) | Automatic (0 to 1000s) | Automatic (consumption plan) |
| **Request Cost** | $0.20/1M requests | $0.40/1M invocations | $0.20/1M executions |
| **Compute Cost** | $0.0000166667/GB-sec | $0.0000083333/GB-sec | Variable by plan |
| **Free Tier** | 1M requests, 400K GB-sec/mo | 2M invocations, 400K GB-sec/mo | 1M requests, 400K GB-sec/mo |
| **State Management** | Via external services | Via Firestore/Datastore | ✅ Durable Functions |
| **Ease of Use** | High (mature platform) | High (simple model) | Very High (with Durable Functions) |

---

### 2.3 Analysis: REST API Backend Recommendation

**For a REST API backend, I would recommend AWS Lambda + API Gateway** for the following reasons:

1. **Maturity & Ecosystem:** Lambda has the most mature ecosystem, extensive community resources, and battle-tested patterns for REST APIs. Thousands of production APIs are running on Lambda.

2. **Performance Optimization:** Provisioned Concurrency effectively eliminates cold start issues for always-on APIs, and the 15-minute timeout is rarely needed for API responses.

3. **API Gateway Integration:** API Gateway provides production-grade features like request/response transformation, request validation, API keys, CORS, and WAF integration without additional configuration.

4. **Cost Efficiency:** Lambda's pricing model ($0.20 per million requests) is competitive. With reserved capacity pricing, costs scale predictably.

5. **Developer Experience:** Extensive tooling (SAM CLI, Serverless Framework) and documentation make development, testing, and deployment straightforward.

**Alternative recommendations:**

- **For Azure Shops:** Azure Functions with Premium Plan for better cold starts and Durable Functions if workflow orchestration is needed
- **For GCP Shops:** Cloud Functions with better pricing ($0.0000083333/GB-sec vs Lambda's $0.0000166667/GB-sec) and longer timeout (60 min)
- **For Multi-Cloud:** Consider Cloud Run (GCP) or Azure Container Instances for containerized APIs with more consistent performance across clouds

---

### 2.4 Advantages and Disadvantages of Serverless Computing

#### Advantages

1. **Reduced Operational Overhead:** No server provisioning, patching, or infrastructure management
2. **Automatic Scaling:** Seamlessly scales from zero to thousands of concurrent executions
3. **Pay-Per-Use Pricing:** Only pay for actual execution time, reducing costs for variable workloads
4. **Fast Time-to-Market:** Deploy functions in minutes without managing infrastructure
5. **Built-in Monitoring & Logging:** Integrated observability and distributed tracing
6. **High Availability:** Multi-region deployment and automatic failover
7. **Reduced Security Surface:** Less infrastructure to patch and secure
8. **Easy Integration:** Deep integration with other cloud services via triggers and bindings

#### Disadvantages

1. **Cold Start Latency:** Initial invocation experiences delay as platform spins up execution environment (100ms-10s+)
2. **Execution Duration Limits:** Maximum runtime enforced (15 min AWS, 60 min GCP, 10-60 min Azure limits long-running processes)
3. **Vendor Lock-In:** Tightly coupled to cloud provider APIs and services; migration between clouds requires rewriting
4. **Debugging Complexity:** Distributed nature makes debugging and troubleshooting more difficult
5. **State Management:** Stateless by design; maintaining state requires external services (databases, caches)
6. **Cost Unpredictability:** Runaway functions can incur unexpected costs without proper safeguards
7. **Limited Customization:** Less control over runtime environment compared to containerized or virtual machine deployments
8. **Testing Challenges:** Local testing doesn't perfectly replicate cloud environment
9. **Concurrency Limits:** Hard concurrency limits per function can bottleneck applications
10. **Monitoring Overhead:** Requires careful instrumentation and logging to understand performance at scale

---

## Conclusion

Artifact registries and serverless computing are foundational technologies in modern DevOps practices. The choice between AWS, GCP, and Azure depends on organizational strategy, existing infrastructure investment, and specific use case requirements. For multi-cloud deployments, organizations often adopt a hybrid approach leveraging each cloud provider's native services with a central artifact management hub for consistency.

---

## References

- AWS ECR Documentation: https://docs.aws.amazon.com/ecr/
- GCP Artifact Registry: https://cloud.google.com/artifact-registry/docs
- Azure Container Registry: https://docs.microsoft.com/en-us/azure/container-registry/
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Google Cloud Functions: https://cloud.google.com/functions/docs
- Azure Functions: https://docs.microsoft.com/en-us/azure/azure-functions/
