# Lab 10 Submission
## Task 1: Artifact Registries Research
### Services, key features, artifact types, integration capabilities:

**AWS: Elastic Container Registry (ECR)**

Amazon ECR is AWS's primary artifact registry service. It is a fully managed service that stores container images and OCI artifacts. The service supports both private and public repositories, providing flexibility for different use cases. Key features include automated vulnerability scanning using Amazon Inspector, lifecycle policies to automatically clean up old images, and cross-region replication. Integration with other AWS services such as ECS, EKS, and Lambda is seamless, and access control is managed through AWS IAM. The pricing model is straightforward: storage and data transfer out to the internet incur costs, with a small free tier available for new users. Common use cases include storing images for microservices on ECS or EKS and sharing public images via the ECR Public Gallery.

**GCP: Artifact Registry**

Google Cloud's primary artifact registry service is Artifact Registry, which serves as the successor to the older Google Container Registry (GCR). This service provides a unified solution for multiple package types. Beyond Docker container images, it supports Maven, npm, Python, Go, Apt, and generic artifacts in a single repository, making it more comprehensive than a standard container registry. Key features include IAM for access control, customer-managed encryption keys, and regional or multi-regional storage options. Integration with Cloud Build, Cloud Run, and GKE is seamless. Pricing is based on storage, data egress, and specific operations such as pushing and pulling artifacts. This service is ideal for teams managing diverse package types for applications running within GCP.

**Azure: Container Registry (ACR)**

Azure Container Registry is Microsoft's solution for artifact storage. Like AWS ECR, it focuses on OCI-compliant images and artifacts. A notable feature is geo-replication, which automatically synchronizes images across different Azure regions to ensure high availability and faster global pulls. The service also includes ACR Tasks, a built-in capability for building, testing, and patching images directly in the cloud. Security integrates with Azure Active Directory and Azure RBAC for permissions, with vulnerability scanning supported through Microsoft Defender for Cloud. ACR offers tiered pricing (Basic, Standard, Premium) based on storage, throughput, and features such as private link support. Common use cases include integration with Azure Kubernetes Service (AKS) and Azure DevOps.

### Comparison table:

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| **Service Name** | Elastic Container Registry | Artifact Registry | Azure Container Registry |
| **Primary Artifact Types** | Container Images, OCI Artifacts | Container Images, Maven, npm, Python, Go, Apt | Container Images, Helm Charts, OCI Artifacts |
| **Key Feature** | Deep AWS IAM integration | Multi-format support (unified) | Geo-replication, ACR Tasks |
| **Security** | IAM, Amazon Inspector | IAM, CMEK | Azure AD, RBAC, Defender for Cloud |
| **Pricing Model** | Pay for storage + data egress | Pay for storage + data egress | Tiered tiers (Basic, Standard, Premium) |

### Analysis:

For a multi-cloud strategy, I would likely choose Google Cloud's Artifact Registry. My reasoning is that while ECR and ACR are excellent services, they are heavily optimized for their specific cloud ecosystems. If you try to use ECR in a GCP environment, you lose the deep integration benefits and might face higher egress costs.

Artifact Registry stands out because of its universal format support. If my company uses GCP for compute but also runs CI/CD pipelines that produce npm or Maven packages, Artifact Registry can store all of that in one place, acting as a central hub. This reduces the overhead of managing multiple separate repositories. Additionally, since it is based on open standards like OCI, it would still work well with other clouds or on-premises Kubernetes clusters, avoiding strict vendor lock-in for the artifact storage layer itself.

## Task 2: Serverless Computing Platform Research

### Service names, key features and capabilities, supported runtimes and languages, pricing, performance characteristics:

**AWS: AWS Lambda**

AWS Lambda is Amazon's primary serverless compute service. It enables code execution without provisioning or managing servers, automatically handling scaling and infrastructure maintenance. Lambda supports multiple programming languages including Node.js, Python, Java, Go, .NET, and Ruby, and also allows custom runtimes packaged as container images. Functions can be triggered by HTTP requests through API Gateway, object changes in S3, messages from SQS or SNS, and scheduled events via CloudWatch Events. Cold start latency varies by runtime, with interpreted languages like Node.js and Python experiencing delays around 200-400 milliseconds, while compiled languages like Java may take several seconds. Provisioned Concurrency is available as a paid feature to keep functions warm and eliminate cold starts. Pricing follows a pay-per-use model based on request count and execution duration measured in GB-seconds. The free tier includes 1 million requests and 400,000 GB-seconds per month. Maximum execution timeout is 15 minutes, with memory configurable up to 10 GB. Common use cases include REST API backends, real-time file processing, event-driven automation, and stream processing.

**GCP: Google Cloud Functions (2nd Gen)**

Google Cloud Functions is Google's serverless compute offering, with the 2nd generation built on Cloud Run. This architecture allows each function instance to handle up to 1,000 concurrent requests, which improves efficiency during traffic spikes compared to the one-request-per-instance model used by other providers. Supported runtimes include Node.js, Python, Go, Java, Ruby, PHP, and .NET. Triggers include HTTP requests and events from Cloud Storage, Pub/Sub, Firestore, and other Google Cloud services. Cold start performance is generally under 200 milliseconds for interpreted languages. The minimum instances feature provides a way to keep functions warm without the complex pricing structure of Provisioned Concurrency. Pricing is based on invocation count and compute time, with a free tier offering 2 million invocations and 400,000 GB-seconds per month. Maximum timeout is 60 minutes, and memory can be configured up to 32 GB. Common use cases include API backends, data processing pipelines, and event-driven applications.

**Azure: Azure Functions**

Azure Functions is Microsoft's serverless compute service. It offers multiple hosting plans: the Consumption plan for pure pay-per-use, the Premium plan with pre-warmed instances to eliminate cold starts, and Dedicated plans for predictable workloads. Supported languages include C#, Node.js, Python, Java, PowerShell, and TypeScript. Functions can be triggered by HTTP requests, blob storage changes, queue messages, timers, and events from other Azure services. A notable feature is Durable Functions, which enables stateful workflows with patterns like function chaining, fan-out/fan-in, and human approval steps directly in code. Another key capability is bindings, which allow declarative connections to input and output services without writing integration code. Cold starts on the Consumption plan can range from 500 milliseconds to several seconds depending on the runtime, while the Premium plan eliminates cold starts with always-ready instances. Pricing varies by plan, with Consumption following per-execution billing similar to AWS and GCP, and Premium having a baseline hourly cost. Free tier includes 1 million requests per month. Maximum timeout is 10 minutes on Consumption and unlimited on Premium. Common use cases include REST APIs, event-driven processing, and orchestrated workflows.

### Comparison table:

| Feature | AWS Lambda | GCP Cloud Functions (2nd Gen) | Azure Functions |
|---------|------------|------------------------------|-----------------|
| **Service Name** | AWS Lambda | Google Cloud Functions | Azure Functions |
| **Supported Languages** | Node.js, Python, Java, Go, .NET, Ruby, custom runtimes | Node.js, Python, Go, Java, Ruby, PHP, .NET | C#, Node.js, Python, Java, PowerShell, TypeScript |
| **Max Timeout** | 15 minutes | 60 minutes | 10 minutes (Consumption) / Unlimited (Premium) |
| **Max Memory** | 10 GB | 32 GB | 1.5 GB (Consumption) / 14 GB (Premium) |
| **Cold Start** | 200-400ms (Node.js), 2-3s (Java) | Under 200ms typical | 500ms-15s (Consumption), eliminated (Premium) |
| **Pricing Model** | Per request + GB-seconds | Per invocation + compute time | Per execution + resource consumption (Consumption) / Hourly (Premium) |
| **Free Tier** | 1M requests + 400K GB-sec | 2M invocations + 400K GB-sec | 1M requests per month |
| **Unique Feature** | Broadest event source integration | 1,000 concurrent requests per instance | Durable Functions for stateful workflows |

### Analysis:

For a REST API backend, Google Cloud Functions 2nd Gen would be the recommended choice. The ability to handle up to 1,000 concurrent requests per instance provides better efficiency during traffic spikes and reduces the number of cold starts experienced by users. The 60-minute timeout offers flexibility for endpoints that may require longer processing times. Additionally, the free tier provides 2 million invocations per month, which is double the allocation from competing services, making it cost-effective for development and low-traffic production workloads.

### Reflection:

Serverless computing offers several advantages. The primary benefit is operational simplicity, as developers can focus on writing code without managing servers, patching operating systems, or configuring scaling infrastructure. Auto-scaling happens automatically, handling traffic spikes without manual intervention. The pay-per-use pricing model ensures cost efficiency, as resources are only consumed when code executes, eliminating idle server costs.

However, there are notable disadvantages. Cold starts introduce latency for infrequently invoked functions, which can impact user experience. Vendor lock-in is a significant concern, as serverless applications often rely on provider-specific triggers, APIs, and tooling, making migration between clouds challenging. Execution limits such as timeout and memory constraints may not suit long-running or memory-intensive workloads. Debugging and observability are also more complex compared to traditional server-based architectures, requiring specialized tools for tracing distributed function calls.