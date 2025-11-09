# Lab 10 — Artifact Registries Research

## Task 1 — Artifact Registries Research

### AWS Artifact Registry Service
- **Service Name:** Amazon Elastic Container Registry (ECR)
- **Supported Artifact Types:** Docker and OCI container images, Python, Java packages
- **Key Features:** 
  - Image vulnerability scanning with Amazon ECR image scanning
  - Lifecycle policies for automated image cleanup
  - Image replication across regions for high availability
  - Encryption at rest using AWS KMS
  - Integration with AWS Identity and Access Management (IAM) for fine-grained access control
  - Private repositories with VPC endpoints for secure access
- **Integration:** 
  - Native integration with Amazon ECS and Amazon EKS for container orchestration
  - Works seamlessly with AWS CodePipeline and AWS CodeBuild for CI/CD
  - Integration with AWS Lambda for serverless workloads
  - Compatible with Docker CLI and Kubernetes
- **Pricing model:** Pay for data storage and transfer
- **Common Use Cases:** 
  - Storing container images for microservices applications
  - CI/CD pipelines for containerized applications
  - Kubernetes deployments on Amazon EKS

### GCP Artifact Registry Service
- **Service Name:** Google Cloud Artifact Registry
- **Supported Artifact Types:** Docker and OCI container images, npm packages, Maven packages (Java), Python packages (PyPI), APT packages (Debian), and Helm charts
- **Key Features:** 
  - Multi-format support for various package types
  - Vulnerability scanning with Container Analysis API
  - Fine-grained IAM permissions and access control
  - Geo-replication across multiple regions
  - Remote repository support for proxying external repositories
- **Integration:** 
  - Integration with Google Cloud Build for CI/CD
  - Native integration with Google Kubernetes Engine (GKE)
  - Works with Cloud Run for serverless container deployments
  - Integrates with Cloud Logging and Cloud Monitoring
- **Pricing model:** Pay for data storage and transfer
- **Common Use Cases:** 
  - Multi-language application artifact storage (Java, Python, Node.js)
  - CI/CD pipelines for diverse application stacks
  - Geo-distributed deployments with regional replication

### Azure Artifact Registry Service
- **Service Name:** Azure Container Registry (ACR)
- **Supported Artifacts:** Docker and OCI container images, OCI artifacts, and Helm charts
- **Key Features:** 
  - Georeplication across multiple Azure regions
  - Azure Active Directory integration for authentication
  - Image vulnerability scanning with Microsoft Defender for Cloud
  - Private endpoints for secure network access
  - Retention policies and lifecycle management
  - Integration with Azure RBAC for access control
- **Integration:** 
  - Native integration with Azure Kubernetes Service (AKS)
  - Integration with Azure DevOps for CI/CD pipelines
  - Compatible with Azure App Service for container deployments
  - Supports Docker CLI and Kubernetes
  - Integrates with Azure Monitor and Azure Log Analytics
  - Works with GitHub Actions and other CI/CD tools
- **Pricing model:** Pay for data storage and data transfer in tiered manner: Basic, Standard, Premium
- **Common Use Cases:** 
  - Container image storage for Azure-based applications
  - Multi-region container deployments
  - Kubernetes deployments on AKS
  - Secure container image distribution

---

### Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| **Primary Focus** | Container images | Multi-format artifacts | Container images |
| **Docker Support** | Yes | Yes | Yes |
| **Multi-format Support** | No (containers only) | Yes (npm, Maven, Python, etc.) | Limited (containers, Helm) |
| **Vulnerability Scanning** | Yes (Amazon ECR) | Yes (Container Analysis) | Yes (Defender for Cloud) |
| **Georeplication** | Yes | Yes | Yes (Premium tier) |
| **IAM Integration** | AWS IAM | Google Cloud IAM | Azure AD/RBAC |
| **CI/CD Integration** | CodePipeline, CodeBuild | Cloud Build | Azure DevOps |
| **Lifecycle Policies** | Yes | Yes | Yes |
| **Content Trust/Signing** | Limited | Yes | Yes |
| **Task Automation** | No | Limited | Yes (ACR Tasks) |

---

### Analysis: Multi-Cloud Strategy Recommendation

For a **multi-cloud strategy**, I would recommend **Google Cloud Artifact Registry** as the primary choice, with the following reasoning:

**Advantages of GCP Artifact Registry for Multi-Cloud:**
1. **Multi-Format Support**: GCP Artifact Registry is the most versatile, supporting not only container images but also npm, Maven, Python packages, and other artifact types. This reduces the need for multiple specialized registries.
2. **Unified Management**: Having a single registry for containers and packages simplifies artifact management across different cloud providers.
3. **Flexibility**: The ability to proxy external repositories and support remote repositories provides flexibility for hybrid cloud scenarios.
4. **Standard Interfaces**: Supports standard package manager protocols, making it easier to integrate with applications running on any cloud provider.


## Task 2 — Serverless Computing Platform Research

### AWS Serverless Computing Platform
- **Service Name:** AWS Lambda
- **Supported Runtimes and Languages:** Node.js, Python, Java, .NET, Go, Ruby, custom runtime
- **Execution Models:** Event-driven (API Gateway, S3, DynamoDB, SQS, SNS, etc.) or HTTP-triggered via API Gateway
- **Cold Start Performance Characteristics:** Cold starts typically 100ms-1s depending on runtime and memory allocation
- **Integration:** 
  - Native integration with API Gateway for REST APIs
  - S3, DynamoDB, SQS, SNS for data processing
  - Step Functions for orchestration
  - CloudWatch for monitoring and logging
- **Pricing Model:** Pay per request and compute time
- **Maximum Execution Duration Limits:** 
  - 15 minutes for synchronous invocations
  - Up to 6 hours for asynchronous invocations (EventBridge)
- **Common Use Cases:** 
  - REST API backends
  - Event-driven data processing

### GCP Serverless Computing Platform
- **Service Name:** Google Cloud Functions (2nd gen) and Cloud Run
- **Supported Runtimes and Languages:** 
  - Cloud Functions: Node.js, Python, Java, Go, .NET, Ruby, PHP
  - Cloud Run: Any language (container-based), supports Docker containers
- **Execution Models:** 
  - Event-driven (Cloud Storage, Pub/Sub, Firestore, etc.)
  - HTTP-triggered (Cloud Run and 2nd gen Functions)
- **Cold Start Performance Characteristics:** 
  - Cloud Functions: Cold starts typically 100ms-2s
  - Cloud Run: Cold starts 100ms-1s (improved with minimum instances)
  - Better cold start performance for frequently used functions
- **Integration:** 
  - Cloud Functions integrate with Cloud Storage, Pub/Sub, Firestore
  - Cloud Run integrates with API Gateway, Cloud Load Balancing
  - Integration with Cloud Build for CI/CD
- **Pricing Model:** Pay per invocation and compute time 
- **Maximum Execution Duration Limits:** Cloud Functions: 60 minutes for 2nd gen
- **Common Use Cases:** 
  - REST API backends (Cloud Run)
  - Event-driven processing
  - Microservices architecture
  - Web applications and APIs

### Azure Serverless Computing Platform
- **Service Name:** Azure Functions
- **Supported Runtimes and Languages:** C#, Java, JavaScript, Python, PowerShell, TypeScript, and container-based deployments (Docker)
- **Execution Models:** 
  - Event-driven (Azure Blob Storage, Event Hubs, Service Bus, etc.)
  - HTTP-triggered (REST APIs)
  - Timer-triggered (scheduled execution)
- **Cold Start Performance:** 
  - Cold starts typically 1-3 seconds depending on runtime
  - Premium plan reduces cold starts significantly
- **Integration:** 
  - Native integration with Azure API Management for APIs
  - Event Grid for event-driven architectures
  - Azure Storage, Cosmos DB, Service Bus
  - Logic Apps for workflow automation
  - Azure AD for authentication
- **Pricing Model:** Pay per execution and compute time in Consumption or Premium plan
- **Maximum Execution Duration:** 
  - Consumption plan: 5 minutes 
  - Premium plan: 30 minutes, unlimited for async
- **Common Use Cases:** 
  - REST API backends
  - Event-driven data processing
  - Scheduled tasks and automation

---

### Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions/Cloud Run | Azure Functions |
|---------|-----------|------------------------------|-----------------|
| **Language Support** | Node.js, Python, Java, .NET, Go, Ruby | Node.js, Python, Java, Go, .NET, Ruby, PHP, Containers | .NET, Java, JavaScript, Python, PowerShell |
| **Container Support** | Yes (up to 10 GB) | Yes (Cloud Run) | Yes |
| **HTTP Trigger** | Yes (via API Gateway) | Yes (Cloud Run, Functions 2nd gen) | Yes |
| **Event-Driven** | Yes| Yes (Cloud services) | Yes (Azure services) |
| **Cold Start** | 100ms-1s | 100ms-2s | 1-3s |
| **Max Execution Duration** | 15 min (sync), 6 hours (async) | 60 min (Cloud Run: up to 24h) | 5 min (Consumption) |
| **Pricing Model** | Pay per request + compute | Pay per request + compute | Pay per execution + compute |
| **Free Tier** | 1M requests, 400K GB-sec | 2M invocations, 400K GB-sec | 1M requests, 400K GB-sec |
| **Monitoring** | CloudWatch | Cloud Monitoring | Application Insights |
| **CI/CD Integration** | CodePipeline, GitHub Actions | Cloud Build, GitHub Actions | Azure DevOps, GitHub Actions |

---

### Analysis: REST API Backend Recommendation

For a **REST API backend**, I would recommend **AWS Lambda with API Gateway** or **GCP Cloud Run**, with the following reasoning:

**AWS Lambda + API Gateway:**
1. **Mature Ecosystem**: AWS Lambda has been available since 2014 and has the most mature ecosystem with extensive documentation and community support.
2. **Excellent Integration**: Seamless integration with API Gateway provides built-in features like request throttling, API versioning, and authentication.
3. **Cost-Effective**: Pay-per-use model is very cost-effective for variable traffic patterns typical in REST APIs.
4. **Cold Start Mitigation**: Provisioned concurrency and SnapStart features help eliminate cold starts for critical endpoints.
5. **Long Execution Time**: 15-minute timeout (or 6 hours for async) is sufficient for most API operations.

**GCP Cloud Run:**
1. **Container Flexibility**: Container-based deployment allows using any language or framework, making it easier to migrate existing applications.
2. **Better for Long-Running**: 60-minute timeout (extendable to 24 hours) is better suited for longer-running API operations.
3. **Consistent Performance**: Minimum instances feature helps maintain consistent performance and reduce cold starts.
4. **Simplified Deployment**: Direct container deployment without needing to package as a function.

**Recommendation:** 
- **For new projects**: Choose **AWS Lambda + API Gateway** if you're building from scratch and want the most mature serverless API solution.
- **For existing containerized apps**: Choose **GCP Cloud Run** if you already have containerized applications or need longer execution times.
- **For .NET-heavy teams**: Consider **Azure Functions** if your team primarily uses .NET and Azure services.

---

### Reflection: Advantages and Disadvantages of Serverless Computing

#### Advantages:

1. **Cost Efficiency**: 
   - Pay only for actual execution time and requests
   - No idle server costs
   - Automatic scaling eliminates over-provisioning

2. **Operational Simplicity**: 
   - No server management or infrastructure maintenance
   - Automatic patching and updates
   - Built-in high availability and fault tolerance

3. **Scalability**: 
   - Automatic scaling from zero to thousands of concurrent executions
   - Handles traffic spikes without manual intervention
   - No capacity planning required

4. **Developer Productivity**: 
   - Faster development and deployment cycles
   - Focus on business logic rather than infrastructure
   - Integrated with cloud services for rapid development

5. **Event-Driven Architecture**: 
   - Natural fit for event-driven and microservices architectures
   - Easy integration with cloud services and event sources
   - Reactive programming model

#### Disadvantages:

1. **Cold Starts**: 
   - Initial latency when functions haven't been used recently
   - Can impact user experience for real-time applications
   - Mitigation strategies (provisioned concurrency) add cost

2. **Execution Time Limits**: 
   - Limited maximum execution duration (varies by platform)
   - Not suitable for long-running processes
   - May require architectural changes for certain workloads

3. **Vendor Lock-in**: 
   - Platform-specific APIs and services
   - Migration between cloud providers can be challenging
   - Dependency on cloud provider's ecosystem

4. **Debugging and Monitoring**: 
   - More complex debugging compared to traditional applications
   - Distributed tracing required for complex workflows
   - Limited local testing capabilities

5. **Cost at Scale**: 
   - Can become expensive at high volumes
   - Pay-per-execution model may not be cost-effective for consistent high traffic
   - Provisioned concurrency adds fixed costs

6. **Limited Control**: 
   - Less control over underlying infrastructure
   - Limited customization of runtime environment
   - Restrictions on system-level configurations

