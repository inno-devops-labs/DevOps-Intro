# lab 10

## Task 1

### Service Names:
- AWS: Amazon Elastic Container Registry (ECR) and Amazon Web Services CodeArtifact
- Azure: Azure Container Registry (ACR) and Azure Artifacts
- GCP: Google Container Registry (GCR)

### Key features:
**AWS (ECR & CodeArtifact):**
* ECR provides built-in vulnerability scanning via Amazon Inspector and supports cross-region replication for container images.
* CodeArtifact acts as a secure caching proxy for public repositories, improving build stability and security for language packages.

**GCP (Google Artifact Registry):**
* Acts as a single, unified service for managing both container images and language packages.
* Provides centralized Identity and Access Management (IAM) and automatic vulnerability scanning out of the box.

**Azure (ACR & Azure Artifacts):**
* ACR features Geo-replication (in the Premium tier) to manage a single registry across multiple global regions, and allows building images directly in the cloud (ACR Tasks).
* Azure Artifacts is deeply integrated into the Azure DevOps ecosystem for seamless CI/CD pipeline management.

### Supported Artifact Types:
* **AWS:** Docker, OCI (ECR); npm, PyPI, Maven, NuGet, yarn (CodeArtifact).
* **GCP:** Docker, OCI, npm, PyPI, Maven, Apt, Yum, Go.
* **Azure:** Docker, OCI, Helm charts (ACR); npm, NuGet, Maven, Python, Universal Packages (Azure Artifacts).

### Integration Capabilities:
* **AWS:** Native integration with Amazon EKS, ECS, and AWS Lambda.
* **GCP:** Seamless integration with Google Kubernetes Engine (GKE) and Cloud Run.
* **Azure:** Deep integration with Azure Kubernetes Service (AKS) and Azure Pipelines.

### Comparison Table

| Feature | AWS (ECR + CodeArtifact) | GCP (Artifact Registry) | Azure (ACR + Artifacts) |
| :--- | :--- | :--- | :--- |
| **Service Structure** | Separate services | Single unified service | Separate services |
| **Security Scanning** | Amazon Inspector | Container Analysis | Microsoft Defender for Cloud |
| **Geo-replication** | Supported | Multi-region support | Available in Premium tier |
| **CI/CD Integration** | AWS CodePipeline | Cloud Build | Azure DevOps / Pipelines |

### Analysis: Multi-cloud Strategy Recommendation
For a multi-cloud strategy, **GCP Artifact Registry** is the most optimal choice. While AWS and Azure require managing separate services for containers and language packages (ECR/CodeArtifact and ACR/Artifacts respectively), GCP offers a fully unified solution. This centralization drastically simplifies Identity and Access Management (IAM) and reduces administrative overhead, allowing DevOps teams to store all types of artifacts in one place before deploying them to any cloud environment.


## Task 2

### Service Names:
* **AWS:** AWS Lambda
* **GCP:** Google Cloud Functions (and Google Cloud Run)
* **Azure:** Azure Functions

### Key Features and Capabilities:
* **AWS Lambda:** Pioneer of serverless computing. Features a massive ecosystem with deep integration into almost all AWS services (e.g., S3 triggers, DynamoDB streams). Supports execution limits up to 15 minutes.
* **GCP Cloud Functions / Cloud Run:** Cloud Functions are great for simple event-driven tasks. Cloud Run is a standout service that allows you to run any stateless containerized application in a fully serverless environment, removing runtime restrictions.
* **Azure Functions:** Features a unique concept called "Bindings" and "Triggers" which allow developers to declaratively connect inputs and outputs (like databases or queues) without writing boilerplate integration code.

### Supported Runtimes and Languages:
* **AWS:** Node.js, Python, Java, C#, Go, Ruby, and custom runtimes.
* **GCP:** Node.js, Python, Go, Java, .NET, Ruby, PHP (Functions); Any language via Docker (Cloud Run).
* **Azure:** C#, Node.js, Python, Java, PowerShell, and custom handlers.

### Pricing Comparison:
All three providers follow a similar "Pay-as-you-go" consumption model:
* Charged based on the **number of invocations** (requests).
* Charged for **compute time** (typically measured in GB-seconds, which is memory allocated multiplied by the execution duration in milliseconds).
* All offer a generous free tier (e.g., 1 million free invocations per month).

### Performance Characteristics:
* **AWS Lambda:** Prone to "cold starts" (latency spikes when a function is invoked after a period of inactivity), especially with heavy runtimes like Java. This is mitigated by paying for "Provisioned Concurrency".
* **GCP:** Cloud Run allows developers to configure `min-instances`, keeping at least one instance "warm" to ensure immediate responses to incoming HTTP requests.
* **Azure Functions:** Cold starts are noticeable on the default Consumption plan. To avoid this for latency-sensitive applications, you must upgrade to the Premium Plan where instances are kept warm.

### Comparison Table

| Feature | AWS Lambda | GCP (Functions/Cloud Run) | Azure Functions |
| :--- | :--- | :--- | :--- |
| **Max Execution Time** | 15 minutes | Up to 60 min (Cloud Run HTTP) | 10 min (Consumption plan) |
| **Container Support** | Yes (via ECR) | Yes (Native via Cloud Run) | Yes |
| **Cold Start Mitigation**| Provisioned Concurrency | Minimum instances | Premium Plan |
| **Unique Highlight** | Massive ecosystem | Any runtime via Docker | Declarative Bindings |

### Analysis: Choosing a Platform for a REST API
For building a REST API backend, **Google Cloud Run** is highly recommended. While the AWS Lambda + API Gateway combination is a mature pattern, it often forces developers to write cloud-specific handler code. Cloud Run allows developers to write a standard REST API using familiar web frameworks (like Express.js, FastAPI, or Spring Boot), package it in a Docker container, and deploy it as a serverless microservice. This provides all the benefits of serverless (auto-scaling to zero, pay-per-use) while completely eliminating vendor lock-in.

### Reflection: Advantages and Disadvantages of Serverless
**Advantages:**
1. **Zero Server Management:** No need to patch operating systems, manage infrastructure, or configure load balancers.
2. **Auto-scaling:** Automatically scales from 0 to thousands of concurrent requests without manual intervention.
3. **Cost-Efficiency:** You only pay for exact compute time. If your application has zero traffic, it costs zero dollars.

**Disadvantages:**
1. **Cold Starts:** Initial requests after a period of inactivity suffer from increased latency.
2. **Vendor Lock-in:** Code and architecture (triggers, permissions) become deeply tied to a specific cloud provider.
3. **Observability and Debugging:** Local testing and tracing errors across distributed serverless functions can be significantly more complex than traditional monolithic applications.