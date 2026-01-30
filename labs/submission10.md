# Lab 10 — Cloud Computing Fundamentals  

## Task 1 — Artifact Registries Research  

### AWS  
- **Service name:** AWS CodeArtifact (for packages) and Amazon Elastic Container Registry (ECR) (for container images)  
- **Supported artifact types:**  
  - **CodeArtifact:** npm, Maven (Java), PyPI (Python), NuGet (.NET) packages  
  - **ECR:** Docker/OCI container images  
- **Key features:**  
  - Fully managed repositories for both packages and container images  
  - Secure, scalable storage with IAM-based access control  
  - Integrated vulnerability scanning (ECR)  
  - Deep integration with AWS CI/CD services (CodeBuild, CodePipeline, ECS, EKS, Fargate)  
- **Integration with other cloud services:**
  - Integrates with CI/CD tools like AWS CodeBuild and AWS CodePipeline for CodeArtifact. 
  - Works with ECS, EKS, Fargate for container image deployments via ECR.
- **Pricing model:** Pay for storage, data transfer, and number of requests  
- **Common use cases:**  
  - CodeArtifact for managing build/package dependencies  
  - ECR for hosting and deploying container images  

### GCP  
- **Service name:** Google Cloud Artifact Registry  
- **Supported artifact types:** Container images (Docker/OCI), npm, Maven, Python, Debian/RPM packages  
- **Key features:**  
  - Unified service for containers and packages  
  - Region-specific repositories for low latency  
  - Fine-grained IAM controls and integrated security scanning  
  - Integration with Cloud Build, GKE, Cloud Run, and CI/CD pipelines  
- **Integration with other cloud services:**
  - Works with Google Cloud Build for storing build artifacts and then deploying to GKE, Cloud Run, Compute Engine, etc. 
- **Pricing model:** Based on storage and network egress; regional repositories can reduce egress costs  
- **Common use cases:**  
  - Centralized repository for multi-artifact builds  
  - Integration with GCP DevOps pipelines and CI/CD tools  

### Azure  
- **Service name:** Azure Artifacts (for packages) and Azure Container Registry (ACR) (for containers)  
- **Supported artifact types:**  
  - **Azure Artifacts:** npm, Maven, NuGet, Python, Cargo, Universal packages  
  - **ACR:** Docker/OCI container images and Helm charts  
- **Key features:**  
  - Integrated with Azure DevOps and GitHub Actions  
  - Geo-replication and private networking for ACR  
  - Artifact caching and upstream sources  
  - RBAC and private link integration for security  
- **Integration with other cloud services:**
  - Integrates with Azure DevOps pipelines, Azure Kubernetes Service (AKS), Azure App Service, machine-learning pipelines.
- **Pricing model:** Tier-based (Basic, Standard, Premium) for ACR; pay for storage and operations  
- **Common use cases:**  
  - Managing internal package feeds for enterprises  
  - Hosting and distributing container images across regions  

### Comparison Table  

| Provider | Registry Service(s) | Artifact Types | Key Differentiators |
|-----------|---------------------|----------------|---------------------|
| **AWS** | CodeArtifact (packages), ECR (containers) | npm, Maven, PyPI, NuGet, Docker/OCI | Strong AWS integration, separate services for packages and images |
| **GCP** | Artifact Registry | Containers + language + OS packages | Unified multi-artifact support, region-specific design |
| **Azure** | Azure Artifacts, Azure Container Registry | npm, Maven, NuGet, Python, Docker/OCI | Deep Azure DevOps integration, geo-replication, caching |

### Similarities

All three cloud providers offer **fully managed artifact registry** services that:

- Support **Docker/OCI images** and **common language package formats** (npm, Maven, PyPI, etc.)
- Provide **fine-grained access control** and **security scanning**
- Integrate tightly with their **own CI/CD ecosystems** (AWS CodePipeline, GCP Cloud Build, Azure DevOps)
- Use a **pay-as-you-go pricing model** based on storage and network usage

### Analysis — Best Choice for Multi-Cloud Strategy  
For a **multi-cloud** setup, **GCP Artifact Registry** is the most versatile choice because it supports multiple artifact types under one service, offers fine-grained IAM, and provides regional optimization.  
However, for optimal performance and cost, using **each cloud’s native registry** for workloads deployed within that cloud (e.g., ECR for AWS, ACR for Azure) is often better.  
A hybrid model with standardized naming and cross-cloud pipelines provides flexibility while reducing vendor lock-in.

---

## Task 2 — Serverless Computing Platform Research  

### AWS  
- **Service name:** AWS Lambda  
- **Supported languages/runtimes:** Node.js, Python, Java, Go, .NET, Ruby, PowerShell, custom runtimes  
- **Execution model:** Event-driven or HTTP-triggered via API Gateway  
- **Key features and capabilities:**
  - Fully managed serverless compute platfor
  - Automatic horizontal scaling (per-request)
  - Integration with over 200 AWS services via triggers and events
  - Provisioned Concurrency option for predictable cold start times
- **Cold start:** Low for interpreted languages (Python, Node.js), higher for compiled (Java, .NET)  
- **Integration:** Deep integration with AWS ecosystem (S3, DynamoDB, SNS/SQS, EventBridge, etc.)  
- **Pricing model:** Pay per invocation + execution time (GB-seconds); free tier available  
- **Execution limits:** Up to 15 minutes per function invocation  
- **Common use cases:** API backends, event-driven automation, microservices, IoT  

### GCP  
- **Service name:** Google Cloud Functions (2nd Gen) / Cloud Run Functions  
- **Supported languages/runtimes:** Node.js, Python, Go, Java, .NET, Ruby, PHP  
- **Execution model:** Event-driven via Eventarc or HTTP-based; containerized runtime on Cloud Run
- **Key features and capabilities:**
  - Based on Cloud Run (containerized serverless model)
  - Supports both HTTP and event-based triggers
  - Concurrency and minimum instances configurable (reduces cold starts)
  - Integrated with Cloud Build, Pub/Sub, Firestore, AI/ML APIs  
- **Cold start:** Tunable with minimum instances and concurrency settings  
- **Integration:** Works with Cloud Storage, Pub/Sub, Firestore, AI/ML, and other GCP services  
- **Pricing model:** Based on vCPU-seconds, GiB-seconds, and request count; free tier available  
- **Execution limits:** Up to 60 minutes for HTTP requests  
- **Common use cases:** REST APIs, event-driven data pipelines, CI/CD automation  

### Azure  
- **Service name:** Azure Functions  
- **Supported languages/runtimes:** C#, F#, JavaScript/TypeScript, Python, Java, PowerShell  
- **Execution model:** Event-driven or HTTP-triggered; available in Consumption, Premium, or Dedicated plans  
- **Key features and capabilities:**
  - Deep integration with Azure and Microsoft ecosystem (Logic Apps, Event Grid, Cosmos DB)
  - Supports Durable Functions for long-running workflows
  - Multiple hosting plans for different performance and cost needs
  - Built-in monitoring with Application Insights
- **Cold start:** Reduced in Premium plan via pre-warmed instances  
- **Integration:** Tight integration with Azure ecosystem (Event Hub, Logic Apps, Cosmos DB)  
- **Pricing model:** Pay-per-execution in Consumption plan; Premium plan adds VNET and scaling control  
- **Execution limits:** Up to 5 minutes (Consumption), longer in Premium plan  
- **Common use cases:** Enterprise APIs, workflow automation, hybrid integration  

### Comparison Table  

| Provider  | Serverless Service(s)                 | Supported Languages                                 | Key Differentiators                                                              |
| --------- | ------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------- |
| **AWS**   | AWS Lambda                            | Node.js, Python, Java, Go, .NET, Ruby               | Mature ecosystem, deep AWS integrations, wide event support                      |
| **GCP**   | Cloud Functions / Cloud Run Functions | Node.js, Python, Go, Java, .NET, PHP                | Unified HTTP and event model, container-based runtime, tunable cold starts       |
| **Azure** | Azure Functions                       | C#, JavaScript/TypeScript, Python, Java, PowerShell | Tight Microsoft ecosystem integration, durable workflows, flexible hosting plans |


### Similarities

All three serverless platforms:
- Provide **fully managed, event-driven compute** with **auto-scaling**
- Support **HTTP-triggered** and **background (event-based)** execution
- Offer **multi-language runtime environments**
- Use a **pay-as-you-go pricing model** (based on invocations or compute time)
- Include **free tiers** and integrate with **their native cloud services** for CI/CD and monitoring

### Analysis — Best Platform for REST API Backend  
For REST APIs, **AWS Lambda** is ideal due to its strong integration with API Gateway, scalability, and ecosystem maturity.  
However, **GCP Cloud Run Functions** offer more flexibility for HTTP-based APIs, better concurrency handling, and lower cold starts.  
For .NET-heavy or enterprise setups, **Azure Functions** is the natural fit due to seamless integration with Azure and hybrid deployment options.  

### Reflection — Advantages and Disadvantages of Serverless Computing  

**Advantages:**  
- No server provisioning or maintenance required  
- Automatic scaling and high availability  
- Pay-per-use model improves cost efficiency  
- Rapid deployment and integration with other cloud services  

**Disadvantages:**  
- Cold start latency can impact performance  
- Execution time limits restrict long-running tasks  
- Vendor lock-in and limited portability  
- Complex debugging and observability  
- Potentially higher costs at sustained high load  

---

## Summary  

- **Artifact Registries:**  
  - AWS, GCP, and Azure each provide strong, secure artifact management tools.  
  - GCP Artifact Registry offers the most unified multi-artifact support.  
- **Serverless Platforms:**  
  - All three providers offer mature FaaS solutions.  
  - Choice depends on ecosystem, performance needs, and developer expertise.  
- **Overall Insight:**  
  - Use native services when staying within one cloud, but for multi-cloud setups, standardize build pipelines and artifact formats for portability.  
