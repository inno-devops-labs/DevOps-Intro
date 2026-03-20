# Lab 10 — Cloud Services Comparative Analysis

## Overview
This lab explores artifact registries and serverless computing platforms across major cloud providers:

- Amazon Web Services (AWS)
- Google Cloud Platform (GCP)
- Microsoft Azure

---

# Task 1 — Artifact Registries Research

## 1.1 Artifact Registry Services

| Cloud Provider | Service Name |
|---------------|-------------|
| AWS | Amazon Elastic Container Registry (ECR) |
| GCP | Google Artifact Registry |
| Azure | Azure Container Registry (ACR) |

---

## Official Documentation

- AWS ECR: https://docs.aws.amazon.com/ecr/
- GCP Artifact Registry: https://cloud.google.com/artifact-registry/docs
- Azure ACR: https://learn.microsoft.com/en-us/azure/container-registry/

---

## 1.2 Key Features

### AWS — Amazon ECR
- Fully managed container registry
- Integration with ECS, EKS, IAM
- Image vulnerability scanning
- Lifecycle policies
- Public and private repositories

### GCP — Google Artifact Registry
- Supports Docker, Maven, npm, Python packages
- Regional repositories
- Fine-grained IAM
- Integration with Cloud Build and GKE

### Azure — Azure Container Registry
- Supports OCI and Docker images
- Geo-replication
- Integration with AKS and Azure DevOps
- Security scanning

---

## Supported Artifact Types

| Service | Containers | Packages | Helm Charts |
|--------|-----------|----------|-------------|
| AWS ECR | Yes | No (limited) | No |
| GCP Artifact Registry | Yes | Yes | Yes |
| Azure ACR | Yes | Limited | Yes |

---

## Integration Capabilities

| Service | CI/CD Integration | Kubernetes Integration | IAM/Auth |
|---------|------------------|------------------------|----------|
| AWS ECR | CodePipeline, CodeBuild, GitHub Actions | Amazon EKS | IAM, resource-based policies |
| GCP Artifact Registry | Cloud Build, Cloud Deploy, GitHub Actions | Google GKE | IAM, VPC Service Controls |
| Azure ACR | Azure DevOps, Azure Pipelines, GitHub Actions | Azure AKS | Azure AD, RBAC |

---

## Pricing (Artifact Registries)

| Service | Pricing Model |
|--------|--------------|
| AWS ECR | Storage-based, free tier includes 500 MB private + 50 GB public |
| GCP Artifact Registry | Pay per storage + network (see pricing page) |
| Azure ACR | Pay per storage tier (Basic, Standard, Premium) |

Links:
- AWS ECR Pricing: https://aws.amazon.com/ecr/pricing/  
- GCP Pricing: https://cloud.google.com/artifact-registry/pricing  
- Azure Pricing: https://azure.microsoft.com/en-us/pricing/details/container-registry/

---

## Comparison Summary

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|--------|--------|----------------------|----------|
| Multi-artifact support | No | Yes | Limited |
| Security scanning | Yes | Yes | Yes |
| Geo-replication | No | Limited | Yes |
| CI/CD integration | Strong | Strong | Strong |

---

## Analysis (Multi-Cloud Strategy)

For a multi-cloud strategy, **Google Artifact Registry** is the best choice.

### Reasons:

1. **Multi-format support**
   - Supports containers AND package formats (npm, Maven, Python)
   - AWS ECR is mostly container-focused

2. **Consistency across environments**
   - Allows standardizing artifact storage across different workloads
   - Useful in polyglot microservices architecture

3. **Better portability**
   - Easier to integrate with non-GCP tools compared to AWS-native ECR

4. **Reduced vendor lock-in**
   - AWS ECR is tightly coupled with AWS ecosystem (ECS/EKS)
   - GCP provides more neutral usage patterns

**Conclusion:** GCP Artifact Registry is more flexible and better suited for heterogeneous, multi-cloud environments.

---

# Task 2 — Serverless Computing Platform Research

## 2.1 Serverless Services

| Cloud Provider | Service Name |
|---------------|-------------|
| AWS | AWS Lambda |
| GCP | Google Cloud Functions |
| Azure | Azure Functions |

---

## Official Documentation

- AWS Lambda: https://docs.aws.amazon.com/lambda/
- GCP Cloud Functions: https://cloud.google.com/functions/docs
- Azure Functions: https://learn.microsoft.com/en-us/azure/azure-functions/

---

## Key Features

### AWS Lambda
- Event-driven compute
- Deep AWS integration (S3, DynamoDB, API Gateway)
- Supports container images
- Highly scalable

### Google Cloud Functions
- Easy deployment
- Tight integration with Firebase and GCP
- Event-driven model

### Azure Functions
- Multiple triggers (HTTP, queue, timer)
- Durable Functions for workflows
- Strong Microsoft ecosystem integration

---

## Supported Runtimes

| Service | Languages |
|--------|----------|
| AWS Lambda | Python, Node.js, Java, Go, .NET, Ruby |
| GCP Cloud Functions | Python, Node.js, Go, Java, Ruby, .NET |
| Azure Functions | C#, Python, JavaScript, PowerShell, Java |

---

## Pricing

| Service | Pricing Details |
|--------|----------------|
| AWS Lambda | $0.20 per 1M requests + compute time |
| GCP Cloud Functions | Pay-per-use model (per invocation + compute time) |
| Azure Functions | $0.20 per 1M executions (consumption plan) |

Links:
- AWS Lambda Pricing: https://aws.amazon.com/lambda/pricing/  
- GCP Pricing: https://cloud.google.com/functions/pricing  
- Azure Pricing: https://azure.microsoft.com/en-us/pricing/details/functions/

---

## Performance Characteristics

| Feature | AWS Lambda | GCP Functions | Azure Functions |
|--------|-----------|--------------|----------------|
| Max memory | 10 GB | 16 GB | 14 GB |
| Cold start | Medium | Fast | Medium |
| Scaling | Very fast | Fast | Fast |
| Max execution time | 15 minutes | 60 minutes | 60 minutes (Consumption) / unlimited (Dedicated) |

---

## Comparison Summary

| Feature | AWS Lambda | GCP Cloud Functions | Azure Functions |
|--------|-----------|---------------------|-----------------|
| Ecosystem | Very strong | Strong | Strong |
| Ease of use | Medium | High | Medium |
| Flexibility | High | Medium | High |
| API Gateway integration | Native | Via API Gateway | Via API Management |

---

## Analysis (REST API Backend)

For a REST API backend, **AWS Lambda** is the best choice.

### Reasons:

1. **Best integration with API Gateway**
   - Native support for REST APIs
   - Easy routing, authentication, throttling, and custom domains

2. **Mature ecosystem**
   - Widely adopted and battle-tested in production
   - Large community, extensive documentation, and tooling

3. **Scalability**
   - Handles sudden traffic spikes automatically
   - Proven track record with large-scale applications

4. **Advanced features**
   - Supports container-based deployment (up to 10 GB)
   - Integration with 200+ AWS services

5. **Cost efficiency at scale**
   - Pay per request model is ideal for APIs with variable load

**Comparison:**
- GCP Cloud Functions is easier to set up but less flexible for complex REST APIs
- Azure Functions is powerful but best suited for Microsoft-centric enterprise stacks

**Conclusion:** AWS Lambda provides the most complete, flexible, and production-ready solution for REST API backends.

---

## Reflection

### Advantages of Serverless
- No infrastructure management
- Automatic scaling
- Pay-per-use pricing
- Faster development cycles
- Reduced operational overhead

### Disadvantages
- Cold start latency
- Vendor lock-in
- Debugging complexity
- Execution time limits
- Testing challenges

---

## Conclusion

Each cloud provider offers strong solutions:

| Provider | Strengths |
|----------|-----------|
| **AWS** | Most mature ecosystem, best integration for REST APIs, widest adoption |
| **GCP** | Best multi-artifact support, simpler developer experience |
| **Azure** | Strong enterprise integration, Microsoft ecosystem synergy |

**Final choice depends on:**
- Existing infrastructure and cloud strategy
- Team expertise and preferred tooling
- Specific application requirements
- Budget and scaling needs