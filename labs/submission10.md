# TASK 1 — Artifact Registries Research

## AWS Artifact Registry

**Service Name:** Amazon Elastic Container Registry (ECR)

**Key Features:**
- Fully managed Docker container registry
- Integrated with AWS Identity and Access Management (IAM) for fine-grained access control
- Image scanning for security vulnerabilities (powered by Amazon Inspector)
- Cross-region and cross-account image replication
- Lifecycle policies for automated image cleanup
- Encryption at rest using AWS KMS
- Pull-through cache for public repositories (Docker Hub, ECR Public, GitHub Container Registry)

**Supported Artifact Types:**
- Docker container images
- OCI-compliant artifacts
- Helm charts (via ECR Public)

**Integration Capabilities:**
- AWS CodeBuild, CodePipeline, and CodeDeploy
- AWS Fargate, ECS, EKS, and Lambda
- AWS Batch
- Third-party CI/CD tools (Jenkins, GitLab CI, GitHub Actions)

**Pricing Model:**
- Storage: $0.10 per GB/month
- Data transfer: $0.09 per GB for data transferred out to the internet
- Image scanning: $0.05 per image scan

---

## GCP Artifact Registry

**Service Name:** Google Artifact Registry

**Key Features:**
- Unified repository for multiple artifact types
- Vulnerability scanning with Container Analysis
- Cloud KMS encryption for stored artifacts
- Remote repositories for caching public packages
- IAM-based access control
- Multi-region support with automatic replication
- Virtual private egress for private IP access

**Supported Artifact Types:**
- Docker container images
- Maven packages
- npm packages
- Python packages
- Go modules
- Apt packages
- Yum packages
- Helm charts

**Integration Capabilities:**
- Google Cloud Build
- Google Kubernetes Engine (GKE)
- Cloud Run
- Cloud Functions
- Vertex AI
- Third-party CI/CD tools

**Pricing Model:**
- Storage: $0.10 per GB/month
- Egress: Standard Google Cloud network egress rates
- Vulnerability scanning: Included at no additional cost

---

## Azure Artifact Registry

**Service Name:** Azure Container Registry (ACR)

**Key Features:**
- Managed Docker registry with geo-replication
- Azure AD integration for authentication and authorization
- Content trust with Notary for image signing
- Vulnerability scanning with Microsoft Defender for Containers
- Webhooks for CI/CD integration
- ACR Tasks for building, testing, and patching images
- Private endpoint support for secure access

**Supported Artifact Types:**
- Docker container images
- OCI artifacts
- Helm charts
- Singularity images

**Integration Capabilities:**
- Azure DevOps
- Azure Kubernetes Service (AKS)
- Azure Container Instances
- Azure Functions
- Azure App Service
- Third-party CI/CD tools

**Pricing Model:**
- Basic tier: $0.167 per GB/day
- Standard tier: $0.167 per GB/day
- Premium tier: $0.167 per GB/day
- Data transfer: Standard Azure egress rates
- Vulnerability scanning: Included with Microsoft Defender

---

## Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure Container Registry |
|---------|---------|----------------------|--------------------------|
| **Container Support** | Docker, OCI | Docker, OCI | Docker, OCI |
| **Package Managers** | None | Maven, npm, Python, Go, Apt, Yum | None |
| **Helm Charts** | ECR Public only | Yes | Yes |
| **Vulnerability Scanning** | Yes ($0.05/scan) | Yes (free) | Yes (with Defender) |
| **Geo-replication** | Yes | Yes | Yes |
| **KMS Encryption** | Yes | Yes | Yes |
| **IAM/AD Integration** | AWS IAM | Cloud IAM | Azure AD |
| **Pull-through Cache** | Yes | Yes | No |
| **Storage Price** | $0.10/GB/month | $0.10/GB/month | $0.167/GB/day (~$5/GB/month) |
| **CI/CD Integration** | AWS services, third-party | GCP services, third-party | Azure services, third-party |

---

## Analysis: Multi-Cloud Strategy Choice

For a multi-cloud strategy, I would choose **Google Artifact Registry** for the following reasons:

1. **Unified Repository:** GCP Artifact Registry supports multiple artifact types (containers, Maven, npm, Python, Go, etc.) in a single service, reducing complexity compared to managing separate services for different artifact types.

2. **Cost-Effective Vulnerability Scanning:** Unlike AWS ECR which charges per scan, GCP includes vulnerability scanning at no additional cost, which can result in significant savings for organizations with frequent builds.

3. **Remote Repositories:** The ability to cache public packages (Maven Central, npm registry, PyPI) reduces external dependencies and improves build reliability.

4. **Consistent Pricing:** The storage pricing is competitive and transparent across all artifact types.

5. **Vendor Neutrality:** While hosted on GCP, the service supports standard formats (OCI, Docker) and integrates well with third-party tools, making it easier to migrate if needed.

However, if the organization is heavily invested in AWS or Azure ecosystems, the native registry services (ECR or ACR) would provide better integration with their respective cloud services. The choice ultimately depends on the organization's primary cloud provider, existing toolchain, and specific requirements for artifact types.

---

# TASK 2 — Serverless Computing Platform Research

## AWS Serverless Computing

**Service Names:**
- AWS Lambda (primary)
- AWS Fargate (serverless containers)

**Key Features and Capabilities:**
- Event-driven compute service
- Automatic scaling from zero to millions of requests
- Built-in monitoring with CloudWatch
- Provisioned Concurrency for reduced cold starts
- Lambda Layers for code sharing
- Event Source Mapping for stream processing
- Aliases and versions for deployment management

**Supported Runtimes and Languages:**
- Node.js (JavaScript/TypeScript)
- Python
- Java
- Go
- Ruby
- .NET (C#)
- Custom runtimes (via Docker container images)
- PowerShell

**Execution Models:**
- Event-driven (S3, SNS, SQS, DynamoDB Streams, Kinesis, etc.)
- HTTP-triggered (via API Gateway, Application Load Balancer)
- Scheduled (via EventBridge)
- Synchronous and asynchronous invocation

**Cold Start Performance:**
- Typical cold start: 100-500ms for lightweight functions
- Provisioned Concurrency eliminates cold starts (at additional cost)
- Container image-based functions have longer cold starts (~1-2 seconds)

**Pricing Model:**
- $0.20 per 1M requests (first 1B requests/month)
- $0.0000166667 per GB-second
- Free tier: 1M requests/month and 400,000 GB-seconds/month

**Maximum Execution Duration:**
- 15 minutes (900 seconds)

**Common Use Cases:**
- REST APIs (with API Gateway)
- Real-time file processing
- Data transformation pipelines
- IoT backends
- Chatbots and voice assistants
- Scheduled tasks and cron jobs

---

## GCP Serverless Computing

**Service Names:**
- Cloud Functions (primary)
- Cloud Run (serverless containers)

**Key Features and Capabilities:**
- Event-driven functions
- Automatic scaling to zero
- Built-in logging and monitoring with Cloud Logging/Monitoring
- Cloud Build integration for CI/CD
- Secret Manager integration
- VPC connector for private network access
- Eventarc for event routing

**Supported Runtimes and Languages:**
- Node.js
- Python
- Go
- Java
- .NET
- Ruby
- PHP
- Custom containers (via Cloud Run)

**Execution Models:**
- Event-driven (Pub/Sub, Cloud Storage, Cloud Firestore, etc.)
- HTTP-triggered (direct HTTP endpoints)
- Scheduled (via Cloud Scheduler)
- Synchronous and asynchronous invocation

**Cold Start Performance:**
- Typical cold start: 200-600ms
- Cloud Run has slightly better cold start performance (~100-400ms)
- Minimum instances can be configured to reduce cold starts

**Pricing Model:**
- Cloud Functions: $0.40 per 1M invocations, $0.0000004 per GB-second
- Cloud Run: $0.40 per 1M requests, $0.0000025 per GB-second
- Free tier: 2M invocations/month for Cloud Functions

**Maximum Execution Duration:**
- Cloud Functions: 60 minutes (3600 seconds)
- Cloud Run: 60 minutes (3600 seconds)

**Common Use Cases:**
- REST APIs (direct HTTP endpoints)
- Event-driven data processing
- Webhooks and integrations
- Microservices
- Background jobs

---

## Azure Serverless Computing

**Service Names:**
- Azure Functions (primary)
- Azure Container Apps (serverless containers)

**Key Features and Capabilities:**
- Event-driven compute service
- Automatic scaling based on demand
- Application Insights for monitoring
- Durable Functions for stateful workflows
- Azure DevOps and GitHub Actions integration
- Managed identities for secure access to Azure resources
- Hybrid connections for on-premises connectivity

**Supported Runtimes and Languages:**
- C# (.NET)
- JavaScript/TypeScript (Node.js)
- Python
- Java
- PowerShell
- F#
- Custom handlers (any language via HTTP)

**Execution Models:**
- Event-driven (Azure Blob, Event Hubs, Service Bus, etc.)
- HTTP-triggered (via HTTP trigger)
- Scheduled (via Timer trigger)
- Synchronous and asynchronous invocation

**Cold Start Performance:**
- Typical cold start: 200-700ms
- Premium plan offers pre-warmed instances for reduced cold starts
- Consumption plan has higher cold start variability

**Pricing Model:**
- Consumption plan: $0.20 per 1M executions, $0.000016/GB-second
- Premium plan: Fixed monthly rate + execution costs
- Free tier: 1M requests/month and 400,000 GB-seconds/month

**Maximum Execution Duration:**
- Consumption plan: 10 minutes (600 seconds)
- Premium plan: Unlimited (60 minutes default)

**Common Use Cases:**
- REST APIs (via HTTP trigger)
- Event processing
- IoT data processing
- Real-time stream processing
- Scheduled tasks
- Workflow orchestration (with Durable Functions)

---

## Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions | Azure Functions |
|---------|-----------|---------------------|-----------------|
| **Primary Service** | Lambda | Cloud Functions | Functions |
| **Container Support** | Yes (container images) | Yes (Cloud Run) | Yes (Container Apps) |
| **Languages** | Node.js, Python, Java, Go, Ruby, .NET, Custom | Node.js, Python, Go, Java, .NET, Ruby, PHP, Custom | C#, Node.js, Python, Java, PowerShell, F#, Custom |
| **HTTP Endpoints** | Via API Gateway | Native | Native |
| **Cold Start** | 100-500ms | 200-600ms | 200-700ms |
| **Max Duration** | 15 min | 60 min | 10 min (Consumption) |
| **Pricing per 1M** | $0.20 | $0.40 | $0.20 |
| **Pricing per GB-sec** | $0.0000166667 | $0.0000004 | $0.000016 |
| **Free Tier** | 1M requests, 400K GB-sec | 2M invocations | 1M requests, 400K GB-sec |
| **Stateful Workflows** | Step Functions | Workflows | Durable Functions |
| **Monitoring** | CloudWatch | Cloud Monitoring | Application Insights |

---

## Analysis: REST API Backend Choice

For a REST API backend, I would choose **AWS Lambda with API Gateway** for the following reasons:

1. **Maturity and Ecosystem:** AWS Lambda has the most mature serverless ecosystem with extensive documentation, community support, and third-party tools (Serverless Framework, SAM, CDK).

2. **Cost-Effective:** At $0.20 per 1M requests, AWS Lambda offers competitive pricing compared to GCP's $0.40 per 1M invocations.

3. **API Gateway Integration:** API Gateway provides comprehensive features for REST APIs including:
   - Request/response transformation
   - Authentication and authorization (Cognito, IAM, JWT)
   - Throttling and rate limiting
   - Custom domain names
   - WebSocket support

4. **Provisioned Concurrency:** For production APIs requiring consistent performance, Provisioned Concurrency eliminates cold starts, ensuring predictable response times.

5. **Deployment Tools:** AWS offers excellent tooling for serverless deployments (SAM, CDK, Serverless Framework) that simplify infrastructure as code and CI/CD integration.

6. **Observability:** CloudWatch provides comprehensive monitoring, logging, and tracing capabilities with X-Ray for distributed tracing.

However, if simplicity and direct HTTP endpoints are priorities, **GCP Cloud Functions** would be a strong alternative since it provides native HTTP endpoints without requiring an additional API gateway service. This reduces complexity and potential points of failure.

---

## Reflection: Advantages and Disadvantages of Serverless Computing

### Advantages

1. **No Server Management:** Developers focus on writing code without worrying about provisioning, scaling, or maintaining servers.

2. **Automatic Scaling:** Functions automatically scale from zero to handle any amount of traffic, paying only for actual usage.

3. **Cost Efficiency:** Pay-per-use pricing model means no costs when functions are not running, ideal for sporadic or unpredictable workloads.

4. **Faster Time to Market:** Reduced infrastructure overhead enables faster development and deployment cycles.

5. **Built-in High Availability:** Cloud providers handle redundancy and fault tolerance automatically.

6. **Simplified Operations:** No need for OS patching, capacity planning, or load balancing configuration.

7. **Event-Driven Architecture:** Natural fit for event-driven patterns and microservices architectures.

### Disadvantages

1. **Cold Starts:** Functions may experience latency when starting after being idle, which can impact performance-sensitive applications.

2. **Vendor Lock-in:** Code and infrastructure become tightly coupled to a specific cloud provider's platform and APIs.

3. **Execution Time Limits:** Maximum execution duration constraints (typically 15 minutes) limit use cases for long-running processes.

4. **Debugging Challenges:** Local development and debugging can be more complex compared to traditional applications.

5. **Statelessness:** Functions are inherently stateless, requiring external services (databases, caches) for state management.

6. **Observability Complexity:** Distributed tracing and monitoring across multiple functions can be challenging to implement effectively.

7. **Cost Predictability:** While pay-per-use is efficient, costs can become unpredictable for high-traffic applications without proper monitoring and budget controls.

8. **Limited Control:** Less control over the underlying infrastructure, which can be problematic for applications with specific performance or compliance requirements.

Serverless computing is ideal for event-driven applications, APIs, microservices, and workloads with variable traffic patterns. However, it may not be suitable for long-running processes, applications requiring consistent low latency, or workloads with predictable, high-volume usage where reserved instances might be more cost-effective.
