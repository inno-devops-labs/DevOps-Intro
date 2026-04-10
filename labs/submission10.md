# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### AWS

- **Service:** Amazon Elastic Container Registry (ECR)

Amazon ECR is a managed container registry designed mainly for storing Docker and OCI images. It is tightly integrated into the AWS ecosystem and works out of the box with services like ECS and EKS.

- **Supported artifacts:**
  - Docker / OCI images  
  - Helm charts  

- **Key features:**
  - Built-in vulnerability scanning  
  - IAM-based access control  
  - High availability without manual setup  
  - Easy integration with AWS services  

- **Integrations:**
  - ECS, EKS, Lambda  
  - CodeBuild, CodePipeline  

- **Pricing:**
  - Pay-as-you-go (~$0.10 per GB/month)

- **Typical use case:**
  - Teams already working fully inside AWS  
  - Container-based microservices  

---

### GCP

- **Service:** Google Artifact Registry

Google Artifact Registry is more flexible compared to AWS and Azure solutions. It supports not only container images, but also multiple package formats, which makes it useful in more diverse environments.

- **Supported artifacts:**
  - Docker images  
  - npm, Maven, Python packages  
  - OS packages (Apt/Yum)  

- **Key features:**
  - Multi-format support  
  - Built-in security scanning  
  - Regional and multi-regional storage  
  - Fine-grained IAM permissions  

- **Integrations:**
  - GKE, Cloud Run  
  - Cloud Build  

- **Pricing:**
  - Small free tier  
  - ~$0.10 per GB/month after  

- **Typical use case:**
  - Mixed tech stacks  
  - Projects with different package types  

---

### Azure

- **Service:** Azure Container Registry (ACR)

Azure Container Registry is designed mainly for enterprise use and works especially well inside the Microsoft ecosystem. It focuses on container storage with strong enterprise features like geo-replication.

- **Supported artifacts:**
  - Docker images  
  - Helm charts  

- **Key features:**
  - Geo-replication  
  - Integration with Azure Active Directory  
  - High performance for image pulls  

- **Integrations:**
  - AKS  
  - Azure DevOps  

- **Pricing:**
  - Tier-based (Basic / Standard / Premium)

- **Typical use case:**
  - Enterprise environments  
  - Microsoft-heavy infrastructure  

---

## Comparison Table

| Cloud | Service | Artifact types | Main strength | Weak point | Best use case |
|------|--------|---------------|--------------|-----------|--------------|
| AWS | ECR | Containers | Deep AWS integration | Limited formats | AWS-native apps |
| GCP | Artifact Registry | Multi-format | Flexibility | Slightly more complex | Multi-cloud / mixed stacks |
| Azure | ACR | Containers | Enterprise features | Less flexible | Microsoft ecosystem |

---

## Analysis — Best choice for multi-cloud strategy

If the goal is to work across multiple cloud providers, flexibility becomes more important than deep integration with a single platform.

AWS ECR and Azure ACR are both strong, but they are mostly focused on container workflows inside their own ecosystems.

Google Artifact Registry stands out because it supports multiple artifact types (not just containers). This makes it easier to use the same registry for different parts of the system without introducing extra tools.

**Conclusion:**  
Google Artifact Registry is the most practical choice for a multi-cloud setup because it is more flexible and reduces dependency on a single cloud provider.

## Sources

- https://aws.amazon.com/ecr/  
- https://aws.amazon.com/ecr/pricing/  
- https://cloud.google.com/artifact-registry  
- https://cloud.google.com/artifact-registry/pricing  
- https://azure.microsoft.com/en-us/products/container-registry  
- https://azure.microsoft.com/en-us/pricing/details/container-registry/

## Task 2 — Serverless Computing Platform Research

### AWS

- **Service:** AWS Lambda

AWS Lambda is the most mature serverless platform. It allows running code in response to events or HTTP requests without managing infrastructure.

- **Supported runtimes:**
  - Node.js, Python, Java, Go, .NET  

- **Execution model:**
  - Event-driven  
  - HTTP via API Gateway  

- **Cold start:**
  - Usually low, especially with optimizations  

- **Integrations:**
  - API Gateway  
  - S3, DynamoDB  
  - Step Functions  

- **Pricing:**
  - Pay per request and execution time  
  - Free tier available  

- **Max duration:**
  - Up to 15 minutes  

- **Typical use case:**
  - APIs, backend logic, event processing  

---

### GCP

- **Service:** Google Cloud Functions

Google Cloud Functions is a simple and lightweight serverless platform. It integrates well with GCP services and is often used for event-based workflows.

- **Supported runtimes:**
  - Node.js, Python, Go, Java  

- **Execution model:**
  - Event-driven  
  - HTTP-triggered  

- **Cold start:**
  - Moderate, but often acceptable for small services  

- **Integrations:**
  - Pub/Sub  
  - Cloud Run  
  - BigQuery  

- **Pricing:**
  - Pay per execution  
  - Free tier available  

- **Max duration:**
  - Up to ~9 minutes (longer in newer versions)  

- **Typical use case:**
  - Lightweight APIs  
  - Data pipelines  

---

### Azure

- **Service:** Azure Functions

Azure Functions is designed with enterprise use in mind and works especially well in Microsoft-based environments.

- **Supported runtimes:**
  - .NET, Node.js, Python, Java  

- **Execution model:**
  - Event-driven  
  - HTTP-triggered  

- **Cold start:**
  - Can be higher on basic plan  

- **Integrations:**
  - Azure Storage  
  - Event Grid  
  - Cosmos DB  

- **Pricing:**
  - Consumption-based  
  - Premium plan available  

- **Max duration:**
  - Limited on basic plan, extended in premium  

- **Typical use case:**
  - Enterprise backend systems  
  - Microsoft ecosystem  

---

## Comparison Table

| Cloud | Service | Strength | Weakness | Max duration | Best use case |
|------|--------|----------|----------|--------------|--------------|
| AWS | Lambda | Mature ecosystem | Slight complexity | 15 min | General-purpose backend |
| GCP | Cloud Functions | Simple & lightweight | Less control | ~9 min | Small services |
| Azure | Functions | Enterprise integration | Cold starts | Flexible (premium) | Enterprise apps |

---

## Analysis — Best choice for REST API backend

When building a REST API, the most important things are stability, latency, and good HTTP integration.

AWS Lambda is the strongest option here because it has the most mature ecosystem and integrates directly with API Gateway. This makes it easy to build scalable APIs without additional infrastructure.

**Conclusion:**  
AWS Lambda is the best choice for a REST API backend due to its stability, ecosystem, and strong integration with API tools.

---

## Reflection — Advantages and disadvantages of serverless computing

### Advantages
- No need to manage servers  
- Automatic scaling  
- Pay only for actual usage  
- Fast deployment  

### Disadvantages
- Cold start delays  
- Execution time limits  
- Vendor lock-in  
- Harder debugging  

Serverless works best for event-driven systems and APIs, but it is not ideal for long-running workloads.