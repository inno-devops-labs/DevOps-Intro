# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### AWS, GCP, Azure Artifact Registry Services

* **AWS – Amazon Web Services:** *Amazon Elastic Container Registry (ECR)* – supports container images & OCI artifacts with features like IAM-based access control, encryption, image scanning/signing, geo-replication, and tight integration with ECS/EKS/Lambda using pay-as-you-go pricing.
* **GCP – Google Cloud Platform:** *Artifact Registry* – supports containers, npm, Maven, Python, etc., with vulnerability scanning, regional/multi-regional storage, and integration with GKE/Cloud Run; pricing is based on storage, network egress, and scanning.
* **Azure – Microsoft Azure:** *Azure Container Registry (ACR)* (+ Azure Artifacts for packages) – supports container images (ACR) and language packages (Artifacts) with geo-replication, RBAC, content trust, and deep Azure DevOps integration using tiered pricing.

### Comparison Table

| Feature               | AWS ECR                                  | GCP Artifact Registry                | Azure ACR / Artifacts                                |
| --------------------- | ---------------------------------------- | ------------------------------------ | ---------------------------------------------------- |
| **Primary Focus**     | Containers (OCI)                         | Universal artifacts                  | Split: ACR (containers) + Artifacts (packages)       |
| **Supported Types**   | Docker images, OCI artifacts             | Containers, npm, Maven, Python, etc. | Containers (ACR), npm/Maven/NuGet/Python (Artifacts) |
| **Security Features** | IAM, encryption, image signing, scanning | IAM, vulnerability scanning          | RBAC, content trust, private endpoints               |
| **Replication**       | Cross-region replication                 | Regional & multi-regional repos      | Geo-replication (premium tier)                       |
| **Integrations**      | ECS, EKS, Lambda, CI/CD tools            | GKE, Cloud Run, CI/CD                | AKS, Azure DevOps, CI/CD                             |
| **Pricing Model**     | Pay-as-you-go (storage + transfer)       | Storage + egress + scanning          | Tiered pricing + storage + bandwidth                 |
| **Unique Strength**   | Deep AWS-native simplicity               | Multi-format unified registry        | Strong DevOps ecosystem integration                  |

### Analysis

For a multi-cloud strategy, GCP Artifact Registry is the best choice because it natively supports multiple artifact types in a single unified service, reducing fragmentation compared to AWS (container-focused) and Azure (split services), making cross-cloud standardization and tooling significantly simpler.

## Task 2 — Serverless Computing Platform Research

### Serverless Compute Services

* **AWS – Amazon Web Services:** *AWS Lambda* (with API Gateway) – event-driven compute supporting many runtimes (Node.js, Python, Java, Go, .NET), with auto-scaling, sub-second billing, deep AWS integrations, and strong ecosystem support.
* **GCP – Google Cloud Platform:** *Cloud Functions* + *Cloud Run* – supports multiple languages (Node.js, Python, Go, Java, .NET) with fast scaling, container-based flexibility (Cloud Run), and per-request billing.
* **Azure – Microsoft Azure:** *Azure Functions* – event-driven service supporting C#, JavaScript, Python, Java, PowerShell with tight integration into Azure services and flexible hosting plans.

### Comparison Table

| Feature                | AWS Lambda                              | GCP Cloud Functions / Run                              | Azure Functions                        |
| ---------------------- | --------------------------------------- | ------------------------------------------------------ | -------------------------------------- |
| **Core Model**         | Function-as-a-Service                   | FaaS + container serverless                            | Function-as-a-Service                  |
| **Languages**          | Node.js, Python, Java, Go, .NET, Ruby   | Node.js, Python, Go, Java, .NET (+ any via containers) | C#, JS, Python, Java, PowerShell       |
| **Scaling**            | Automatic, very granular                | Automatic, fast (Cloud Run scales to zero)             | Automatic with multiple plans          |
| **Pricing**            | Per request + execution time (ms)       | Per request + CPU/memory time                          | Per execution + execution time         |
| **Cold Starts**        | Moderate (improving with SnapStart)     | Often faster (esp. Cloud Run)                          | Can be higher depending on plan        |
| **Max Execution Time** | Up to 15 min                            | Functions: ~60 min / Run: longer                       | Up to ~60 min (plan-dependent)         |
| **Integration**        | Deep AWS ecosystem (S3, DynamoDB, etc.) | Strong with GCP (Pub/Sub, Firebase, etc.)              | Strong with Azure (Event Grid, DevOps) |
| **Flexibility**        | Limited runtime control                 | High (containers in Cloud Run)                         | Moderate                               |

### Analysis

For a REST API backend, GCP Cloud Run stands out because it supports containerized workloads, avoids many cold-start issues, and provides more control over runtime and dependencies compared to pure FaaS models like Lambda or Azure Functions.

### Reflection

**Advantages:**

* No infrastructure management (fully managed)
* Automatic scaling (including scale-to-zero)
* Cost-efficient for variable workloads (pay-per-use)
* Faster development and deployment cycles

**Disadvantages:**

* Cold start latency can impact performance
* Limited execution time and runtime control
* Vendor lock-in due to tight cloud integrations
* Debugging and observability can be more complex
