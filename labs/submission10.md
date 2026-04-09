# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### AWS — Amazon Elastic Container Registry (ECR)
- Fully managed container registry
- Supports Docker & OCI images
- IAM integration + vulnerability scanning
- Integrates with ECS, EKS, Lambda

### GCP — Artifact Registry
- Multi-format support (Docker, npm, Maven, Python)
- Regional repositories + built-in scanning
- IAM integration
- Integrates with GKE, Cloud Build, Cloud Run

### Azure — Azure Container Registry (ACR)
- Managed private registry
- Docker + Helm charts
- Geo-replication support
- Integrates with AKS, DevOps

### Comparison Table

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
|---------|---------|----------------------|-----------|
| Artifact types | Docker, OCI | Docker, npm, Maven, Python | Docker, Helm |
| Vulnerability scan | ✅ | ✅ | ✅ |
| Geo-replication | ✅ | ✅ | ✅ |
| IAM integration | ✅ | ✅ | ✅ |

**Multi-cloud choice:** GCP Artifact Registry — supports most artifact types, reduces tool sprawl.

---

## Task 2 — Serverless Computing Platforms

### AWS — Lambda
- Event-driven, auto-scaling
- Runtimes: Python, Node.js, Java, Go, .NET
- Pay per request + duration
- Cold starts: 100-300ms

### GCP — Cloud Functions (2nd gen) / Cloud Run
- Functions + container-based serverless
- Runtimes: Python, Node.js, Go, Java, .NET
- Pay per execution
- Cold starts: 50-200ms (Cloud Run lower)

### Azure — Functions
- Event-driven + Durable Functions
- Runtimes: C#, Python, JavaScript, Java
- Pay per execution
- Cold starts: 200-500ms

### Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions/Run | Azure Functions |
|---------|------------|------------------------|-----------------|
| Max execution | 15 min | 60 min | 10 min |
| Container support | Limited | Full (Cloud Run) | Limited |
| Cold start latency | Moderate | Low | Moderate |
| Free tier | 1M req/month | 2M invocations/month | 1M executions/month |

**REST API choice:** GCP Cloud Run — container flexibility, lower cold starts, simpler deployment.

### Reflection

**Advantages:**
- No server management
- Auto-scaling to zero
- Pay-per-use cost model

**Disadvantages:**
- Cold start latency
- Execution time limits
- Vendor lock-in risk