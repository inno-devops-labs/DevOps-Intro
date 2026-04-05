# Task 1 — Artifact Registries Research

## Service name for each cloud provider

```
AWS offers two main services: Amazon Elastic Container Registry (ECR) for container images and OCI artifacts, and AWS CodeArtifact for software package management (npm, Maven, PyPI, NuGet). GCP provides a unified solution called Google Cloud Artifact Registry, which handles both container images and language packages in a single service. Azure primarily uses Azure Container Registry (ACR) for container and OCI artifacts, while package management is handled through Azure Artifacts within Azure DevOps.
```


## Key features of each artifact registry

```
AWS ECR (Elastic Container Registry) features deep integration with ECS, EKS, and Lambda; vulnerability scanning through Amazon Inspector; automated image cleanup with lifecycle policies; and cross-region replication for global workloads. AWS CodeArtifact adds caching proxy for external repositories like npmjs and Maven Central, plus fine-grained IAM access control.

GCP Artifact Registry offers a unified platform managing both containers and language packages together; automatic vulnerability scanning for OS and language packages; fine-grained IAM permissions at the repository level; and multi-region geo-replication for high availability.

Azure Container Registry (ACR) includes geo-replication with multi-master support across Azure regions; integration with Azure Active Directory and RBAC for security; ACR Tasks for automated container building and patching; and Private Link with Virtual Network support for private connectivity.
```


## Supported artifact types


```
AWS ECR: Docker images, OCI images, OCI artifacts
AWS CodeArtifact: npm, Maven, PyPI, NuGet packages
GCP Artifact Registry: Docker/OCI images, Helm charts, npm, Maven, PyPI, Go, Apt, YUM packages
Azure ACR: Docker images, OCI images, Helm charts, OCI artifacts
```



## Integration capabilities


```
AWS ECR: Integrates with ECS, EKS, Lambda, and CodeBuild
AWS CodeArtifact: Integrates with CodeBuild, CodePipeline, and acts as proxy for npmjs, Maven Central, PyPI
GCP Artifact Registry: Integrates with Cloud Build, Cloud Run, GKE, and Cloud Functions
Azure ACR: Integrates with AKS, App Service, ACR Tasks, and Azure DevOps
```



## Comparison table highlighting similarities and differences

| Feature | AWS (ECR) | GCP (Artifact Registry) | Azure (ACR) |
|---------|-----------|------------------------|-------------|
| **Primary Focus** | Container images | Universal (containers + packages) | Container images |
| **Supported Types** | Docker, OCI | Docker, Helm, npm, Maven, PyPI, Go, Apt, YUM | Docker, OCI, Helm |
| **Vulnerability Scanning** | Yes (Inspector) | Yes (Container Analysis) | Yes (Security Center) |
| **Geo-Replication** | Yes (cross-region) | Yes (multi-region) | Yes (Premium SKU) |
| **Automated Cleanup** | Lifecycle policies | Yes | ACR Tasks |
| **Package Proxy** | No (CodeArtifact does) | No | No (Azure Artifacts does) |
| **Private Networking** | VPC endpoints | VPC SC + Private Google Access | Private Link + VNet |
| **API Request Charges** | Yes ($0.40 per 1K) | No | No (included in SKU) |


```
Key Similarities: All three support container images, vulnerability scanning, IAM integration, and geo-replication options.

Key Differences: GCP is the only unified registry supporting both containers and language packages in one service. AWS splits container (ECR) and package (CodeArtifact) management into separate services. Azure also splits container (ACR) and package (Azure Artifacts) management, but ACR uniquely offers built-in automated container building (ACR Tasks).
```


## Analysis: Which registry service would you choose for a multi-cloud strategy and why?


```
For a multi-cloud strategy, GCP Artifact Registry would be the best choice because it is the only service that natively supports both container images and multiple package formats (npm, Maven, PyPI, etc.) in a single unified platform, reducing operational overhead. However, if you need a cloud-agnostic solution, third-party registries like Docker Hub or JFrog Artifactory are actually more suitable than any single cloud provider's native service, as they avoid vendor lock-in and work seamlessly across AWS, GCP, and Azure simultaneously. Between the native options, AWS ECR and Azure ACR are both excellent but lock you into their respective ecosystems, making cross-cloud replication and unified access management significantly more complex.
```




# Task 2 — Serverless Computing Platform Research

## Service name(s) for each cloud provider

```
AWS offers three main serverless compute services: AWS Lambda (Function-as-a-Service for event-driven code), AWS Fargate (serverless compute engine for containers), and AWS App Runner (fully managed service for deploying containerized web applications and APIs).

GCP provides Cloud Run (container-based serverless platform that runs stateless HTTP-driven containers) and Cloud Run Functions (formerly Cloud Functions, a function-as-a-service platform for event-driven code).

Azure primarily uses Azure Functions as its core FaaS offering, along with Azure Container Apps for serverless containerized applications
```


## Key features and capabilities

```
AWS Lambda automatically scales from zero to thousands of concurrent executions without manual configuration, natively integrates with over 220 AWS services, and supports Java, Go, Node.js, Python, C#, Ruby, and PowerShell with custom runtimes. Key capabilities include provisioned concurrency to minimize cold starts, SnapStart for up to 10x faster Java startup, and Firecracker MicroVM isolation for security.

GCP Cloud Run is a fully managed container-based platform that automatically scales containerized applications from zero and supports any programming language via containers. Key capabilities include built-in traffic splitting for running multiple revision versions concurrently, direct VPC egress to databases, multi-region deployments behind a global load balancer, and native integration with Cloud Monitoring and SLO tracking.

Azure Functions runs event-driven code with support for C#, Java, JavaScript, Python, PowerShell, and custom handlers. Key capabilities include Durable Functions for stateful orchestration across multiple agents, multiple hosting plans (Consumption scales to zero, Premium with pre-warmed instances, Flex Consumption up to 1,000 instances), and deep integration with Azure services through triggers and bindings.

AWS App Runner and Azure Container Apps are additional serverless container options — App Runner provides the simplest way to deploy web services from source code or containers, while Container Apps offers Kubernetes-style microservices with Dapr and KEDA integration.
```


## Supported runtimes and languages


```
AWS Lambda: Node.js, Python, Java, Go, C#, Ruby, PowerShell, and custom runtimes via Runtime API.

GCP Cloud Run: Any language or runtime - since it runs containers, you can use anything (Node.js, Python, Go, Java, Ruby, PHP, .NET, etc.).

Azure Functions: C#, Java, JavaScript, Python, PowerShell, TypeScript, and custom handlers.
```


## Pricing comparison

```
AWS Lambda charges $0.20 per 1 million requests and $0.0000166667 per GB-second of compute time. The free tier includes 1 million requests and 400,000 GB-seconds per month. Billing is in 1ms increments. Provisioned concurrency (keeping functions warm) costs extra at $0.000004167 per GB-second .

Azure Functions (Consumption plan) matches AWS almost exactly: $0.20 per 1 million executions and $0.000016 per GB-second, with the same free tier of 1 million executions and 400,000 GB-seconds. The newer Flex Consumption plan is slightly more expensive at $0.40 per million executions and $0.000026 per GB-second, but offers configurable memory and "Always Ready" instances .

GCP Cloud Run functions (2nd gen) charges $0.40 per 1 million invocations, plus vCPU usage at approximately $0.000024 per vCPU-second and memory at $0.0000025 per GB-second. The free tier is more generous: 2 million invocations, 180,000 vCPU-seconds, and 360,000 GiB-seconds per month .
```


## Performance characteristics

```
AWS Lambda: Cold starts: Python/Node.js 200-400ms, Java 2-5 sec (SnapStart reduces to 90-140ms). Max timeout: 15 min. Graviton2 ARM64 is 15-40% faster.

GCP Cloud Run: Cold starts ~200ms. Max timeout: 60 min. Fastest cold starts among the three.

Azure Functions: Cold start varies: Consumption plan scales to zero, Premium has pre-warmed instances (no cold start). HTTP trigger hard limit: 230 sec.
```


## Comparison table highlighting similarities and differences

| Feature | AWS Lambda | GCP Cloud Run | Azure Functions |
|---------|------------|---------------|-----------------|
| **Primary Model** | FaaS (functions) | Container-based (any language) | FaaS + container |
| **Cold Start** | 200-400ms (Python/Node), 2-5s (Java) | ~200ms | Depends on plan (Premium = none) |
| **Max Timeout** | 15 min | 60 min | 230 sec (HTTP) |
| **Free Tier** | 1M requests + 400K GB-s | 2M invocations | 1M executions + 400K GB-s |
| **Pricing** | $0.20/M req + $0.0000167/GB-s | $0.40/M inv + vCPU/mem | Same as AWS ($0.20/M + $0.000016/GB-s) |
| **Language Support** | Node, Python, Java, Go, C#, Ruby, PowerShell | Any (container) | C#, Java, JS, Python, PowerShell |



```
Key Similarities: All three scale to zero, charge per invocation + compute time, offer generous free tiers, and integrate deeply with their cloud ecosystems.

Key Differences: GCP Cloud Run is the only container-native serverless platform, allowing any language. Azure has the shortest HTTP timeout (230 sec). AWS offers SnapStart for Java cold start optimization.
```


## Analysis: Which serverless platform would you choose for a REST API backend and why?

```
For a REST API backend, GCP Cloud Run is the best choice because it supports any programming language via containers, has the fastest cold starts (~200ms), and offers the longest request timeout (60 minutes), which is ideal for APIs handling variable processing times. AWS Lambda with Amazon API Gateway is a strong alternative if you are already invested in AWS, but Java cold starts can be problematic. Azure Functions is less suitable due to the hard 230-second HTTP timeout, which can cause timeouts for longer-running API requests.
```


## Reflection: What are the main advantages and disadvantages of serverless computing?


*Advantages of serverless computing:*


```
No server management - operations overhead is eliminated

Automatic scaling from zero to thousands of concurrent executions

Pay-per-use pricing - no cost for idle time

Faster development and deployment cycles

Built-in high availability and fault tolerance
```


*Disadvantages of serverless computing:*


```
Cold start latency can impact user experience

Execution timeout limits restrict long-running workloads

Vendor lock-in due to proprietary APIs and event sources

Debugging and monitoring are more complex than traditional servers

Higher costs for consistently high-throughput workloads compared to dedicated instances
```


# Sources

### AWS
- Amazon ECR Documentation: https://docs.aws.amazon.com/ecr/
- AWS CodeArtifact Documentation: https://docs.aws.amazon.com/codeartifact/
- AWS Lambda Documentation: https://docs.aws.amazon.com/lambda/
- AWS Fargate Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
- AWS App Runner Documentation: https://docs.aws.amazon.com/apprunner/

### GCP
- Artifact Registry Documentation: https://cloud.google.com/artifact-registry/docs
- Cloud Run Documentation: https://cloud.google.com/run/docs
- Cloud Functions Documentation: https://cloud.google.com/functions/docs

### Azure
- Azure Container Registry Documentation: https://learn.microsoft.com/en-us/azure/container-registry/
- Azure Artifacts Documentation: https://learn.microsoft.com/en-us/azure/devops/artifacts/
- Azure Functions Documentation: https://learn.microsoft.com/en-us/azure/azure-functions/
- Azure Container Apps Documentation: https://learn.microsoft.com/en-us/azure/container-apps/