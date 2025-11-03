# Lab Submission 10 — Artifact Registries Research

# Task 1 — Artifact Registries Research
### AWS Artifact Registry
- **Service Name:** Amazon Elastic Container Registry (ECR)  
- **Supported Artifacts:** Container images (Docker, OCI), Helm charts  
- **Key Features:** Vulnerability scanning, lifecycle policies, encryption at rest, IAM-based access control, geo-replication  
- **Integration:** Works with ECS, EKS, Lambda, CodePipeline, CloudFormation  
- **Pricing:** Pay per GB stored and data transferred  
- **Common Use Cases:** Storing container images for AWS-based deployments  

### GCP Artifact Registry
- **Service Name:** Google Artifact Registry  
- **Supported Artifacts:** Container images (Docker, OCI), Maven, npm, Python packages  
- **Key Features:** Vulnerability scanning, fine-grained IAM, geo-replication, regional repositories  
- **Integration:** GKE, Cloud Build, Cloud Run, Cloud Functions  
- **Pricing:** Pay per GB stored and data transferred  
- **Common Use Cases:** Multi-language package management and container storage in GCP  

### Azure Artifact Registry
- **Service Name:** Azure Container Registry (ACR)  
- **Supported Artifacts:** Container images (Docker, OCI), Helm charts, OCI artifacts  
- **Key Features:** Vulnerability scanning (Microsoft Defender), geo-replication, RBAC, Azure AD integration  
- **Integration:** AKS, Azure DevOps, Azure Pipelines, App Service  
- **Pricing:** Tiered pricing (Basic, Standard, Premium) based on storage and features  
- **Common Use Cases:** Managing container images for Azure deployments  

---

### 📊 Comparison Table

| Feature / Provider | AWS ECR | GCP Artifact Registry | Azure ACR |
|------------------|---------|---------------------|------------|
| Supported Artifacts | Docker, OCI, Helm | Docker, OCI, Maven, npm, Python | Docker, OCI, Helm |
| Vulnerability Scanning | ✅ | ✅ | ✅ |
| Geo-replication | ✅ | ✅ | ✅ |
| Access Control | IAM | IAM roles | RBAC, Azure AD |
| Integration | ECS, EKS, Lambda | GKE, Cloud Build | AKS, Azure DevOps |
| Pricing Model | Storage & transfer | Storage & transfer | Tiered |

---

### 🧠 Analysis

For a **multi-cloud strategy**, **Google Artifact Registry** is the most flexible because it supports **both containers and multiple package types (Maven, npm, Python)**. Its regional repositories and strong integration with GCP DevOps tools make it suitable for hybrid workflows. AWS ECR and Azure ACR are excellent if your workloads are primarily within their respective clouds, but for multi-cloud portability, GCP provides broader artifact support and consistent management.

# Task 2 — Serverless Computing Platform Research

### AWS Serverless Computing
- **Service Name:** AWS Lambda  
- **Supported Runtimes:** Node.js, Python, Java, Go, Ruby, .NET, custom runtimes  
- **Execution Model:** Event-driven (S3, DynamoDB, API Gateway, CloudWatch events)  
- **Cold Start Performance:** Typically <1s for warm functions; longer for large packages  
- **Integration:** API Gateway, S3, DynamoDB, SNS, CloudWatch, Step Functions  
- **Pricing:** Pay per invocation and execution time (GB-seconds)  
- **Max Execution Duration:** 15 minutes  
- **Use Cases:** REST APIs, event-driven automation, ETL tasks  

### GCP Serverless Computing
- **Service Name:** Google Cloud Functions  
- **Supported Runtimes:** Node.js, Python, Go, Java, .NET  
- **Execution Model:** Event-driven (Cloud Pub/Sub, Cloud Storage, HTTP triggers)  
- **Cold Start Performance:** ~100ms–1s for lightweight functions  
- **Integration:** Cloud Pub/Sub, Cloud Storage, Firestore, HTTP endpoints  
- **Pricing:** Pay per invocation, execution time, and memory  
- **Max Execution Duration:** 9 minutes  
- **Use Cases:** REST APIs, microservices, event processing  

### Azure Serverless Computing
- **Service Name:** Azure Functions  
- **Supported Runtimes:** C#, JavaScript, Python, Java, PowerShell, custom containers  
- **Execution Model:** Event-driven or HTTP-triggered  
- **Cold Start Performance:** ~1–2s depending on plan; Premium plan avoids cold starts  
- **Integration:** Event Grid, Storage, Service Bus, Logic Apps, API Management  
- **Pricing:** Pay per execution and execution time; Premium plan for pre-warmed instances  
- **Max Execution Duration:** 5 minutes (Consumption plan), unlimited for Premium  
- **Use Cases:** Serverless APIs, background jobs, event-driven workflows  

---

### 📊 Comparison Table

| Feature / Provider | AWS Lambda | GCP Cloud Functions | Azure Functions |
|------------------|------------|------------------|----------------|
| Supported Languages | Node.js, Python, Java, Go, Ruby, .NET | Node.js, Python, Go, Java, .NET | C#, JS, Python, Java, PowerShell |
| Execution Model | Event-driven | Event-driven | Event-driven / HTTP |
| Max Execution Time | 15 min | 9 min | 5 min (Consumption) / Unlimited (Premium) |
| Pricing | Per invocation & GB-s | Per invocation & GB-s | Per execution & time |
| Integration | AWS services | GCP services | Azure services |
| Cold Start | Low (<1s warm) | Low (~100ms–1s) | Moderate (~1–2s, Premium avoids) |

---

### 🧠 Analysis
For a **REST API backend**, **AWS Lambda** with **API Gateway** is a strong choice due to:
- Broad language/runtime support  
- High scalability and mature integrations  
- Long max execution time (15 min)  
- Rich ecosystem for monitoring and security  

---

### 💭 Reflection
**Advantages of Serverless:**  
- No server management, automatic scaling  
- Pay only for execution time  
- Quick deployment of event-driven workloads  

**Disadvantages:**  
- Cold start latency for infrequently used functions  
- Execution time limits on standard plans  
- Vendor lock-in risks  
- Limited control over underlying infrastructure
