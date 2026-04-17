# **Lab 10 — Cloud Computing Fundamentals**

## **Task 1 — Artifact Registries Research**

### **Artifact Registry Services Overview**

| Service | Cloud Provider | Official Name | Supported Artifacts |
|---------|--------------|---------------|-------------------|
| AWS | Amazon Web Services | Amazon ECR (Elastic Container Registry) | Docker/OCI container images, Helm charts |
| GCP | Google Cloud Platform | Artifact Registry | Docker/OCI images, Maven, npm, Python, Go packages |
| Azure | Microsoft Azure | Azure Container Registry | Docker/OCI images, Helm charts, OCI artifacts |

### **AWS ECR Details**

```bash
# ECR is integrated with AWS IAM for authentication
# Supports public and private registries
# Features: vulnerability scanning, image replication, lifecycle policies
```

* Supported artifacts: Docker and OCI container images, Helm charts
* Key features: 

  - Integrated with IAM for access control
  - Vulnerability scanning with Amazon Inspector
  - Cross-region and cross-account replication
  - Public gallery for sharing Docker images
* Pricing: pay for storage and data transfer

### **GCP Artifact Registry Details**

```bash
# Native Docker registry replacing GCR
# Supports multiple format repositories in one registry
# Integrated with Cloud IAM and KMS for security
```

* Supported artifacts: Docker/OCI images, Maven, npm, Python, Go, Debian packages
* Key features: 

  - Vulnerability scanning with Container Analysis
  - Multi-format support in single registry
  - Regional and multi-regional storage
  - Integration with Cloud Build and Cloud Run
* Pricing: based on storage and network egress

### **Azure Container Registry Details**

```bash
# ACR supports Docker and OCI images
# Admin user for simplified access
# Geo-replication for global distribution
```

* Supported artifacts: Docker/OCI images, Helm charts, OCI artifacts
* Key features: 

  - Azure AD authentication
  - Geo-replication
  - Task automation for builds
  - Vulnerability scanning (Microsoft Defender)
* Pricing: tiered based on storage and operations

### **Comparison Analysis**

| Criterion | AWS ECR | GCP Artifact Registry | Azure ACR |
|-----------|---------|---------------------|-----------|
| Artifact formats | Docker, OCI, Helm | Docker, Maven, npm, Python, Go, Debian | Docker, OCI, Helm |
| Security scanning | Inspector | Container Analysis | Microsoft Defender |
| Replication | Cross-region | Multi-region | Geo-replication |
| IAM integration | Native | Native | Azure AD |

* Multi-cloud strategy choice: For a multi-cloud strategy, I would choose **GCP Artifact Registry** because it supports the widest variety of artifact formats (Docker, Maven, npm, Python, Go, Debian) in a single registry, reducing the need for multiple separate services across different cloud providers. It also offers strong integration with Google Cloud Build and Cloud Run.

## **Task 2 — Serverless Computing Platform Research**

### **Serverless Platform Services Overview**

| Service | Cloud Provider | Official Name | Max Duration |
|---------|---------------|---------------|-------------|
| AWS | Amazon Web Services | AWS Lambda | 15 minutes |
| GCP | Google Cloud Platform | Cloud Functions / Cloud Run | 60 minutes (2nd gen) |
| Azure | Microsoft Azure | Azure Functions | Unlimited (Premium) / 30 min (Consumption) |

### **AWS Lambda Details**

```bash
# Support for Python, Node.js, Java, Go, Ruby, .NET, custom runtime
# Pay per request and execution time
# Cold start: ~200-500ms for provisioned concurrency
```

* Supported runtimes: Python, Node.js, Java, Go, Ruby, .NET, Custom Runtime
* Execution models: HTTP triggers via API Gateway, event-driven via S3/SNS/SQS, etc.
* Cold start: 200-500ms typical, instant with provisioned concurrency
* Pricing: $0.20 per 1M requests, $0.0000166667 per GB-second
* Max duration: 15 minutes
* Common use cases: REST APIs, data processing, event handling

### **Google Cloud Functions Details**

```bash
# 1st gen: Node.js, Python, Go, Java, .NET
# 2nd gen: extended runtimes, bigger memory, longer execution
# Event-driven and HTTP-triggered
```

* Supported runtimes: Node.js, Python, Go, Java, .NET, Ruby, PHP (1st gen)
* Execution models: HTTP triggers, event functions, Cloud Events
* Cold start: ~100-300ms typical
* Pricing: free tier 2M invocations, then $0.40 per 1M + $0.000024 per GB-second
* Max duration: 60 minutes (2nd gen functions)
* Common use cases: HTTP APIs, data processing, lightweight microservices

### **Azure Functions Details**

```bash
# Supports C#, Java, JavaScript, PowerShell, Python, TypeScript
# Multiple hosting plans: Consumption, Premium, App Service
# Durable Functions for stateful workflows
```

* Supported runtimes: C#, Java, JavaScript, PowerShell, Python, TypeScript, Go, Ruby
* Execution models: HTTP triggers, timer, event-driven (Service Bus, Event Hubs), Webhooks
* Cold start: ~200-600ms typical
* Pricing: Consumption: $0.20 per 1M requests, $0.000016 per GB-second
* Max duration: Unlimited (Premium plan), 30 minutes (Consumption)
* Common use cases: REST APIs, background processing, stateful workflows (Durable Functions)

### **Comparison Table**

| Criterion | AWS Lambda | GCP Cloud Functions | Azure Functions |
|-----------|-----------|-------------------|---------------|
| Languages | Python, Node, Java, Go, Ruby, .NET | Node, Python, Go, Java, .NET, Ruby | C#, Java, JS, PS, Python, TS |
| Max duration | 15 min | 60 min | Unlimited (Premium) |
| Cold start | ~200-500ms | ~100-300ms | ~200-600ms |
| Pricing/1M req | $0.20 | $0.40 | $0.20 |
| Stateful | No | No | Yes (Durable Functions) |

### **REST API Backend Choice**

For a REST API backend, I would choose **AWS Lambda** because:

1. Mature ecosystem with API Gateway integration
2. Strong community support and extensive documentation
3. Provisioned concurrency eliminates cold starts for production APIs
4. Wide language support and established best practices
5. Low cost at low traffic with generous free tier

### **Serverless Computing Reflection**

**Advantages:**

- No server management overhead
- Automatic scaling from zero to thousands of instances
- Pay-per-use pricing model
- Fast deployment and iteration
- Built-in high availability

**Disadvantages:**

- Vendor lock-in concerns
- Cold start latency
- Execution duration limits
- Limited control over infrastructure
- Debugging and monitoring challenges in production
- Unpredictable costs at scale

(End of file - total 226 lines)