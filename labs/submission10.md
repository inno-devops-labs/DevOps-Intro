# Task

## Task 1 — Artifact Registries Research 

### 1.1: Research Artifact Registries
#### AWS - Amazon ECR (Elastic Container Registry)
**Service Name:** Amazon Elastic Container Registry (ECR)

**Key Features:**
- Fully managed Docker container registry
- Integrated with AWS Identity and Access Management (IAM)
- Automatic image scanning for vulnerabilities
- Cross-region replication
- Lifecycle policies for automated image management
- Private and public registry options
- Integration with AWS Copilot for container deployment

**Supported Artifact Types:**
- Docker/OCI container images
- Helm charts
- Open Container Initiative (OCI) artifacts

**Integration Capabilities:**
- Native integration with ECS, EKS, and Fargate
- CI/CD integration with AWS CodePipeline and CodeBuild
- Works with Kubernetes through standard Docker commands
- API and CLI support for automation

#### GCP - Artifact Registry
**Service Name:** Google Artifact Registry

**Key Features:**
- Unified artifact management service
- Multi-format support (replaced Container Registry)
- Fine-grained access control with IAM
- Vulnerability scanning
- Multi-regional repositories
- Immutable tags and versioning
- Integration with Cloud Build and GKE

**Supported Artifact Types:**
- Docker/OCI container images
- Maven packages
- npm packages
- Python packages
- APT and YUM repositories
- Generic artifacts

**Integration Capabilities:**
- Native integration with Google Kubernetes Engine (GKE)
- Cloud Build for CI/CD pipelines
- Integration with Cloud Deploy
- Support for standard package managers
- REST API and client libraries

#### Azure - Azure Container Registry (ACR)
**Service Name:** Azure Container Registry

**Key Features:**
- Geo-replication across multiple regions
- Azure Active Directory integration
- Automated container builds (ACR Tasks)
- Content trust and image signing
- Vulnerability scanning with Qualys
- Dedicated data endpoints
- Premium performance tiers

**Supported Artifact Types:**
- Docker/OCI container images
- Helm charts
- OCI artifacts
- Build artifacts (through ACR Tasks)

**Integration Capabilities:**
- Tight integration with Azure Kubernetes Service (AKS)
- Azure DevOps pipelines
- GitHub Actions integration
- Service principals for automated access
- Webhooks for event-driven workflows

### Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| **Primary Service** | Elastic Container Registry | Artifact Registry | Container Registry |
| **Pricing Model** | Storage + data transfer | Storage + operations | Tier-based (Basic/Standard/Premium) |
| **Vulnerability Scanning** | Integrated (basic free, advanced paid) | Integrated | Integrated with Qualys |
| **Multi-region Support** | Cross-region replication | Multi-regional repos | Geo-replication (Premium tier) |
| **Access Control** | IAM policies | IAM roles | Azure AD + RBAC |
| **CI/CD Integration** | CodePipeline, CodeBuild | Cloud Build | Azure DevOps, GitHub Actions |
| **K8s Integration** | EKS | GKE | AKS |
| **Multi-format Support** | Limited (containers focus) | Extensive (multiple package types) | Container-focused with some extensions |
| **Build Services** | Through CodeBuild | Cloud Build integration | ACR Tasks (built-in) |
| **Content Trust** | Basic | Available | Available |

### Analysis: Multi-Cloud Strategy Recommendation

For a multi-cloud strategy, I would recommend **Google Artifact Registry** as the primary choice, with the following rationale:

**Why GCP Artifact Registry:**
1. **Superior Multi-Format Support**: GCP Artifact Registry supports the widest variety of artifact types (containers, Maven, npm, Python, etc.), making it more versatile for diverse development teams.

2. **Cloud-Agnostic Design**: While all registries can be accessed from any cloud, GCP's artifact registry has the most standardized API approach that works well across different environments.

3. **Cost-Effective Operations**: The pricing model based on storage and operations is more predictable and often more cost-effective for multi-cloud scenarios compared to tier-based pricing.

4. **Strong Standards Compliance**: Excellent support for OCI standards ensures better interoperability across different container runtimes and orchestration platforms.

5. **Flexible Access Patterns**: Well-documented REST APIs and client libraries that work consistently across cloud boundaries.

**Alternative Considerations:**
- **AWS ECR** would be the choice if heavily invested in AWS ecosystem with predominantly container-based workloads
- **Azure ACR** excels in Microsoft-centric environments and offers excellent geo-replication capabilities

**Hybrid Approach Recommendation:**
For true multi-cloud resilience, consider implementing a **registry synchronization strategy** using tools like Skopeo or registry replicators to maintain copies of critical artifacts across multiple cloud registries, with GCP Artifact Registry serving as the primary source of truth due to its superior format flexibility and cost structure.

# Task 2 — Serverless Computing Platform Research

## 2.1: Research Serverless Computing Platforms

### AWS - AWS Lambda
**Service Name:** AWS Lambda

**Key Features and Capabilities:**
- Event-driven compute service
- Automatic scaling from zero to thousands of concurrent executions
- Subsecond billing (1ms increments)
- Integrated with 200+ AWS services
- Lambda Extensions for monitoring, security, and governance
- Provisioned Concurrency for predictable performance
- SnapStart for faster Java cold starts
- Dead Letter Queues (DLQ) for error handling

**Supported Runtimes and Languages:**
- Node.js, Python, Java, C#, Go, Ruby
- Custom runtimes (any language via Runtime API)
- Docker container support (up to 10GB)
- .NET, PowerShell

**Pricing:**
- Pay per request: $0.20 per 1 million requests
- Compute cost: $0.0000166667 per GB-second
- Free tier: 1 million requests and 400,000 GB-seconds monthly

**Performance Characteristics:**
- Cold starts: 100ms - 5s (depending on runtime and memory)
- Memory: 128MB to 10GB
- Execution timeout: 15 minutes
- Temporary storage: 512MB to 10GB

### GCP - Cloud Functions
**Service Name:** Google Cloud Functions (2nd gen)

**Key Features and Capabilities:**
- Event-driven and HTTP-triggered functions
- Automatic scaling with concurrency up to 1,000
- Direct integration with Google Cloud services
- Cloud EventArc for event management
- Built-in security with IAM and identity tokens
- Traffic splitting for gradual deployments
- Connectors for VPC access

**Supported Runtimes and Languages:**
- Node.js, Python, Java, Go, .NET, Ruby, PHP
- Custom runtimes via Docker containers
- Second-generation supports more languages

**Pricing:**
- Invocations: $0.40 per million invocations
- Compute time: $0.0000025 per GHz-second
- Memory: $0.00000350 per GB-second
- Free tier: 2 million invocations monthly

**Performance Characteristics:**
- Cold starts: Improved in 2nd gen (faster initialization)
- Memory: 128MB to 16GB
- Execution timeout: 60 minutes (2nd gen)
- Concurrency: Up to 1,000 concurrent requests

### Azure - Azure Functions
**Service Name:** Azure Functions

**Key Features and Capabilities:**
- Multiple hosting plans (Consumption, Premium, Dedicated)
- Durable Functions for stateful workflows
- Azure Functions Scale Controller for intelligent scaling
- Integrated with Azure Monitor and Application Insights
- Isolated worker process for .NET applications
- Virtual network integration
- Managed identities for secure access

**Supported Runtimes and Languages:**
- C#, Java, JavaScript, Python, PowerShell, TypeScript
- Custom handlers (any language)
- Docker container support
- .NET isolated process

**Pricing:**
- Consumption plan: $0.20 per million executions + $0.000016/GB-s
- Premium plan: Fixed monthly + per execution costs
- Free grant: 1 million requests and 400,000 GB-s monthly

**Performance Characteristics:**
- Cold starts: Varies by plan (Premium has pre-warmed instances)
- Memory: Up to 3.5GB (Consumption) or 14GB (Premium)
- Execution timeout: 5-30 minutes depending on plan
- Scale out: Up to 200 instances (Consumption)

## 2.2: Document Your Findings

| Feature | AWS Lambda | GCP Cloud Functions | Azure Functions |
|---------|------------|---------------------|-----------------|
| **Primary Service** | Lambda | Cloud Functions | Azure Functions |
| **Max Timeout** | 15 minutes | 60 minutes (2nd gen) | 30 minutes (Premium) |
| **Max Memory** | 10GB | 16GB | 14GB (Premium) |
| **Cold Start Performance** | Moderate (SnapStart for Java) | Good (2nd gen improved) | Varies by plan |
| **Pricing Model** | Request + duration | Request + CPU+memory | Plan-based + usage |
| **Free Tier** | 1M requests | 2M requests | 1M requests |
| **State Management** | Limited (external services) | Limited (external services) | Durable Functions |
| **VPC Integration** | Yes (additional cost) | Yes (connectors) | Yes (all plans) |
| **Container Support** | Up to 10GB images | Custom containers | Custom containers |
| **Native Integrations** | 200+ AWS services | Google Cloud services | Azure services |

## Analysis: REST API Backend Recommendation

For a REST API backend, I would recommend **AWS Lambda** with API Gateway for the following reasons:

**Why AWS Lambda:**
1. **Mature API Gateway Integration**: AWS API Gateway + Lambda is a proven, battle-tested combination with extensive features for REST API development including request validation, transformation, caching, and authorization.

2. **Performance Consistency**: With Provisioned Concurrency, AWS Lambda can maintain predictable performance for APIs with steady traffic patterns, eliminating cold starts for critical endpoints.

3. **Rich Ecosystem**: Extensive middleware options, frameworks (Serverless Framework, SAM), and monitoring tools specifically designed for API development.

4. **Cost Efficiency**: For typical API workloads with bursty traffic patterns, AWS Lambda's pricing with 1ms billing granularity often proves more cost-effective.

5. **Enterprise Features**: Advanced security, WAF integration, and comprehensive logging/monitoring make it suitable for production APIs.

**Alternative Scenarios:**
- **GCP Cloud Functions** would be ideal for heavy Google Cloud integrations or when longer timeout limits (60 minutes) are required
- **Azure Functions** excels for .NET-heavy teams or when needing Durable Functions for complex workflows

## Reflection: Serverless Computing Advantages and Disadvantages

### Main Advantages:

1. **Reduced Operational Overhead**: No server management, patching, or infrastructure maintenance required
2. **Automatic Scaling**: Handles traffic spikes seamlessly without manual intervention
3. **Cost Efficiency**: Pay only for actual compute time rather than reserved capacity
4. **Faster Time to Market**: Developers can focus on business logic rather than infrastructure
5. **High Availability**: Built-in fault tolerance and cross-AZ deployment
6. **Event-Driven Architecture**: Natural fit for modern microservices and event-based systems

### Main Disadvantages:

1. **Cold Start Latency**: Initial invocation delays can impact user experience for infrequently used functions
2. **Execution Time Limits**: Not suitable for long-running processes (maximum 15-60 minutes)
3. **Vendor Lock-in**: Tight coupling with cloud provider's ecosystem and services
4. **Debugging Complexity**: Distributed tracing and monitoring require specialized tools
5. **Resource Constraints**: Memory, storage, and CPU limitations may not suit all workloads
6. **Cost Uncertainty**: Can become expensive with high, consistent traffic compared to dedicated instances
7. **Local Testing Challenges**: Difficult to perfectly replicate cloud environment locally

### When to Use Serverless:
- **Ideal for**: REST APIs, event processing, data transformation, scheduled tasks, microservices
- **Avoid for**: Long-running processes, high-performance computing, stateful applications, predictable heavy traffic

Serverless computing represents a significant shift in application architecture that offers compelling benefits for the right use cases, but requires careful consideration of its limitations and trade-offs.