# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### AWS — Amazon Elastic Container Registry (ECR)
**Key Features:**
- Fully managed container registry
- Integration with IAM for access control
- Image scanning for vulnerabilities
- High availability and scalability

**Supported Artifacts:**
- Docker container images
- OCI-compatible artifacts

**Integration:**
- AWS ECS, EKS, Lambda
- CI/CD tools (CodePipeline, GitHub Actions)

---

### GCP — Artifact Registry
**Key Features:**
- Unified repository for multiple artifact types
- Regional repositories
- Built-in vulnerability scanning
- Fine-grained access control via IAM

**Supported Artifacts:**
- Docker images
- npm, Maven, Python packages

**Integration:**
- Google Kubernetes Engine (GKE)
- Cloud Build, Cloud Run

---

### Azure — Azure Container Registry (ACR)
**Key Features:**
- Managed private container registry
- Geo-replication support
- Built-in security and authentication
- Webhooks and tasks for automation

**Supported Artifacts:**
- Docker images
- Helm charts

**Integration:**
- Azure Kubernetes Service (AKS)
- Azure DevOps, GitHub Actions

---

### Comparison Table

| Feature                | AWS ECR          | GCP Artifact Registry | Azure ACR        |
|----------------------|------------------|----------------------|------------------|
| Artifact Types       | Docker, OCI      | Docker, npm, Maven   | Docker, Helm     |
| Vulnerability Scan   | Yes              | Yes                  | Yes              |
| Multi-region         | Yes              | Yes                  | Yes              |
| IAM Integration      | Yes              | Yes                  | Yes              |
| CI/CD Integration    | Strong           | Strong               | Strong           |

---

### Analysis

For a multi-cloud strategy, GCP Artifact Registry is the most flexible choice because it supports multiple artifact types (not only containers), making it more универсальный for diverse pipelines.

---

## Task 2 — Serverless Computing Platforms

### AWS — AWS Lambda
**Key Features:**
- Event-driven execution
- Automatic scaling
- No server management
- Deep AWS ecosystem integration

**Supported Runtimes:**
- Python, Node.js, Java, Go, .NET

**Pricing:**
- Pay per request and execution time

---

### GCP — Cloud Functions / Cloud Run
**Key Features:**
- Cloud Functions for event-driven workloads
- Cloud Run for container-based serverless
- Fast scaling and deployment

**Supported Runtimes:**
- Python, Node.js, Go, Java, .NET

**Pricing:**
- Pay per execution time and requests

---

### Azure — Azure Functions
**Key Features:**
- Event-driven serverless compute
- Integration with Azure services
- Durable Functions for workflows

**Supported Runtimes:**
- C#, Python, JavaScript, Java

**Pricing:**
- Pay-per-execution model

---

### Comparison Table

| Feature              | AWS Lambda       | GCP Cloud Functions / Run | Azure Functions |
|--------------------|------------------|--------------------------|-----------------|
| Scaling            | Automatic        | Automatic                | Automatic       |
| Container Support  | Limited          | Full (Cloud Run)         | Limited         |
| Cold Start         | Moderate         | Low (Cloud Run)          | Moderate        |
| Pricing Model      | Pay-per-use      | Pay-per-use              | Pay-per-use     |
| Ecosystem          | Very strong      | Strong                   | Strong          |

---

### Analysis

For a REST API backend, GCP Cloud Run is the best option because it supports containers, provides fast scaling, and reduces cold start issues compared to traditional serverless functions.

---

### Reflection

**Advantages of Serverless:**
- No server management
- Automatic scaling
- Cost-efficient for variable workloads

**Disadvantages:**
- Cold start latency
- Limited control over infrastructure
- Vendor lock-in