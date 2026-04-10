# Lab 10 — Cloud Services Research

## Task 1 — Artifact Registries Research

### 1.1 Service Names

| Cloud Provider | Service Name |
|----------------|-------------|
| AWS | Amazon Elastic Container Registry (ECR) |
| GCP | Google Artifact Registry |
| Azure | Azure Container Registry (ACR) |

---

### 1.2 Key Features

#### AWS — Amazon ECR
- Fully managed container registry
- Native integration with ECS, EKS, and Lambda
- Image scanning for vulnerabilities
- Fine-grained IAM access control
- Lifecycle policies for image cleanup
- Cross-region replication

#### GCP — Artifact Registry
- Supports multiple artifact formats (Docker, Maven, npm, Python, etc.)
- Regional repositories
- Built-in vulnerability scanning
- Integration with Cloud Build and GKE
- IAM-based access control
- Repository-level permissions

#### Azure — Azure Container Registry
- Supports Docker and OCI images
- Geo-replication support
- Integration with AKS and Azure DevOps
- Built-in security scanning (via Defender)
- Role-based access control (RBAC)
- Webhooks and automation triggers

---

### 1.3 Supported Artifact Types

| Provider | Supported Types |
|----------|----------------|
| AWS ECR | Container images (Docker/OCI) |
| GCP Artifact Registry | Containers, Maven, npm, Python, Go, Apt, Yum |
| Azure ACR | Container images (Docker/OCI), Helm charts |

---

### 1.4 Integration Capabilities

| Provider | Integrations |
|----------|-------------|
| AWS | ECS, EKS, Lambda, CodeBuild, CodePipeline |
| GCP | GKE, Cloud Build, Cloud Run, IAM |
| Azure | AKS, Azure DevOps, GitHub Actions |

---

### 1.5 Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|--------|--------|----------------------|-----------|
| Multi-artifact support | ❌ | ✅ | Partial |
| Vulnerability scanning | ✅ | ✅ | ✅ |
| Native CI/CD integration | Strong | Strong | Strong |
| Geo-replication | ✅ | Limited | ✅ |
| IAM integration | ✅ | ✅ | ✅ |
| Ease of use | High | High | High |

---

### 1.6 Analysis — Best Choice for Multi-Cloud Strategy

**Best choice: GCP Artifact Registry**

**Reasoning:**
- Supports multiple artifact formats beyond containers
- Easier to standardize across different environments
- More flexible for polyglot and microservices architectures
- Better suited for heterogeneous deployments in multi-cloud setups

AWS ECR and Azure ACR are excellent but primarily container-focused, which limits flexibility in broader DevOps pipelines.

---

## Task 2 — Serverless Computing Platform Research

### 2.1 Service Names

| Cloud Provider | Service Name |
|----------------|-------------|
| AWS | AWS Lambda |
| GCP | Google Cloud Functions / Cloud Run |
| Azure | Azure Functions |

---

### 2.2 Key Features and Capabilities

#### AWS Lambda
- Event-driven execution
- Deep AWS ecosystem integration
- Automatic scaling
- Supports multiple triggers (S3, API Gateway, DynamoDB)
- Provisioned concurrency to reduce cold starts

#### GCP Cloud Functions / Cloud Run
- Cloud Functions: event-driven serverless
- Cloud Run: container-based serverless
- Fast scaling and HTTP-based execution
- Strong integration with GCP services
- Supports custom containers (Cloud Run)

#### Azure Functions
- Event-driven architecture
- Tight integration with Azure services
- Durable Functions for workflows
- Multiple triggers (HTTP, queue, timer)
- Consumption and premium plans

---

### 2.3 Supported Runtimes

| Provider | Languages |
|----------|----------|
| AWS Lambda | Node.js, Python, Java, Go, .NET, Ruby |
| GCP | Node.js, Python, Go, Java, .NET, Ruby |
| Azure | C#, JavaScript, Python, Java, PowerShell |

---

### 2.4 Pricing Comparison

| Provider | Pricing Model |
|----------|--------------|
| AWS Lambda | Pay per request + execution time |
| GCP | Pay per execution time and CPU/memory |
| Azure | Pay per execution (Consumption Plan) |

All providers offer free tiers.

---

### 2.5 Performance Characteristics

| Feature | AWS Lambda | GCP Cloud Run | Azure Functions |
|--------|-----------|--------------|----------------|
| Cold start latency | Medium | Low (Cloud Run optimized) | Medium |
| Scaling speed | Fast | Very fast | Fast |
| Max execution time | 15 min | Unlimited (Cloud Run) | 60 min |
| Container support | Limited | Full (Cloud Run) | Partial |

---

### 2.6 Comparison Table

| Feature | AWS Lambda | GCP Cloud Run | Azure Functions |
|--------|-----------|--------------|----------------|
| Ease of use | High | High | High |
| Flexibility | Medium | Very high | Medium |
| Container support | Limited | Full | Partial |
| Scaling | Automatic | Automatic | Automatic |
| Ecosystem integration | Excellent | Excellent | Excellent |

---

### 2.7 Analysis — Best for REST API Backend

**Best choice: GCP Cloud Run**

**Reasoning:**
- Supports full containerized applications
- No strict runtime limitations
- Handles HTTP services natively
- Scales to zero efficiently
- Better control over environment and dependencies

AWS Lambda is excellent but less flexible for complex APIs. Azure Functions is comparable but less flexible than Cloud Run.

---

### 2.8 Reflection — Advantages and Disadvantages of Serverless

#### Advantages
- No infrastructure management
- Automatic scaling
- Pay-as-you-go pricing
- Faster development and deployment
- High availability by default

#### Disadvantages
- Cold start latency
- Limited execution time (except Cloud Run)
- Vendor lock-in
- Debugging complexity
- Less control over environment

---

## Conclusion

- GCP provides the most flexible artifact registry and serverless platform for multi-cloud and modern architectures.
- AWS offers the most mature ecosystem and integrations.
- Azure provides strong enterprise integration, especially for Microsoft-based environments.

Each provider is viable, but the optimal choice depends on architecture requirements and ecosystem alignment.