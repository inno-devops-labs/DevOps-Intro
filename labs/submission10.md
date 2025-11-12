# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries

### Service Overview  
| Provider | Service Name | Supported Artifacts | Key Features | Integrations | Basic Pricing Model | Notes |
|----------|--------------|--------------------|--------------|--------------|---------------------|-------|
| AWS      | Amazon ECR   | Docker / OCI images ([aws.amazon.com](https://aws.amazon.com/ecr/features/?utm_source=chatgpt.com)) | Supports Docker and OCI images, uses S3 for storage, IAM access control, vulnerability scanning ([docs.aws.amazon.com](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html?utm_source=chatgpt.com)) | ECS, EKS, CI/CD tools ([docs.aws.amazon.com](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr-use-cases.html?utm_source=chatgpt.com)) | Pay for storage and data transfer ([docs.aws.amazon.com](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html?utm_source=chatgpt.com)) | Good option if you use AWS infrastructure |
| GCP      | Artifact Registry | Containers, packages (npm, Maven, etc.) ([docs.cloud.google.com](https://cloud.google.com/artifact-registry/docs?utm_source=chatgpt.com)) | Supports multiple artifact formats, geo-replication, no egress fees within the same region ([docs.cloud.google.com](https://cloud.google.com/artifact-registry/docs/repositories?utm_source=chatgpt.com)) | GKE, Cloud Build, etc. | Storage: first 0.5 GB free, then about $0.10/GB-month ([docs.cloud.google.com](https://cloud.google.com/artifact-registry/pricing?utm_source=chatgpt.com)) | Suitable for mixed artifact types |
| Azure    | Azure Container Registry (ACR) | Containers, Helm charts, OCI images | Geo-replication, RBAC, DevOps integration | AKS, Azure DevOps | Tiered pricing (Basic, Standard, Premium) | Works well if you use mostly Azure services |

### Analysis  
- GCP Artifact Registry is flexible because it supports multiple artifact types, which might be useful in mixed environments.  
- AWS ECR is a solid choice if your workloads run mainly on AWS and you want easy integration with ECS or EKS.  
- Azure Container Registry fits best when your environment is mostly Azure-based.

---

## Task 2 — Serverless Computing Platforms

### Service Overview  
| Provider | Service Name | Supported Languages / Runtimes | Max Execution Duration | Pricing Model | Cold Start Performance | Integrations | Notes |
|----------|--------------|-------------------------------|-----------------------|---------------|------------------------|--------------|-------|
| AWS      | AWS Lambda   | Python, Node.js, Java, Go, C#, PowerShell, Ruby, Custom runtimes ([docs.aws.amazon.com](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html?utm_source=chatgpt.com)) | 15 minutes | Pay per invocation + duration ([aws.amazon.com](https://aws.amazon.com/lambda/pricing/?utm_source=chatgpt.com)) | Moderate | API Gateway, S3, DynamoDB, CloudWatch, EventBridge | Widely used with mature ecosystem |
| GCP      | Cloud Functions / Cloud Run | Node.js, Python, Go, Java, .NET, Ruby, PHP, Custom containers ([cloud.google.com](https://cloud.google.com/functions/docs/concepts/runtime?utm_source=chatgpt.com)) | 9 minutes (Cloud Functions), up to 60+ minutes (Cloud Run) | Pay per invocation + CPU/memory | Fast | Pub/Sub, Storage, HTTP triggers | Cloud Run supports containers and longer runs |
| Azure    | Azure Functions | C#, JavaScript, Python, Java, PowerShell, Custom handlers ([docs.microsoft.com](https://learn.microsoft.com/azure/azure-functions/supported-languages?utm_source=chatgpt.com)) | 10 minutes by default, unlimited with Premium plan | Pay per execution time and resources | Medium | Logic Apps, Event Grid, Service Bus | Good integration with Microsoft tools |

### Analysis  
- AWS Lambda is often chosen for REST APIs because of its integration with API Gateway and broad support.  
- GCP Cloud Run is useful if you want to run containerized workloads or need longer execution times.  
- Azure Functions works well if your infrastructure is mostly Microsoft-based.

### Advantages and Disadvantages

**Advantages:**  
- No need to manage servers  
- Automatic scaling  
- Pay only for what you use  
- Faster to develop and deploy  

**Disadvantages:**  
- Cold start delays can affect performance  
- Debugging can be harder than traditional servers  
- Possible vendor lock-in  
- Limits on execution time and resources

---

## Conclusion

Artifact registries and serverless platforms differ in features, pricing, and integrations. GCP Artifact Registry supports various artifact types and is flexible for multi-format use. AWS Lambda is a mature and popular choice for serverless computing, especially in AWS environments. The best option depends on your existing infrastructure and specific needs.
