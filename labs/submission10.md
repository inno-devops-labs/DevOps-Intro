# Task 1 
## 1. AWS

### Service name
Amazon Elastic Container Registry (ECR)

### Supported artifact types
- Docker container images
- OCI-compatible images

### Key features
- Fully managed container registry
- Integration with AWS IAM for access control
- Image vulnerability scanning
- Lifecycle policies for image cleanup
- Encryption at rest and in transit

### Integrations
- Amazon ECS
- Amazon EKS
- AWS CodeBuild and CodePipeline
- AWS IAM

### Pricing model basics
- Pay for storage (GB per month)
- Pay for data transfer (outbound traffic)
- No upfront cost, pay-as-you-go model

### Common use cases
- Storing Docker images for microservices
- CI/CD pipelines for containerized applications
- Deployments to ECS and EKS

---

## 2. GCP

### Service name
Google Artifact Registry

### Supported artifact types
- Container images (Docker, OCI)
- Helm charts
- Maven packages
- npm packages
- Python packages

### Key features
- Supports multiple artifact formats
- Regional repositories
- Built-in vulnerability scanning
- Fine-grained IAM access control
- Repository separation by format

### Integrations
- Google Kubernetes Engine (GKE)
- Google Cloud Build
- Cloud Run
- Google Cloud IAM

### Pricing model basics
- Pay for storage used
- Pay for network egress
- Additional charges for operations depending on usage

### Common use cases
- Storing container images and application packages
- CI/CD pipelines in Google Cloud
- Managing dependencies for applications

---

## 3. Azure

### Service name
Azure Container Registry (ACR)

### Supported artifact types
- Docker container images
- OCI artifacts

### Key features
- Private container registry
- Geo-replication across regions
- Role-based access control (RBAC)
- Image versioning and tagging
- Automated builds (ACR Tasks)

### Integrations
- Azure Kubernetes Service (AKS)
- Azure DevOps
- GitHub Actions
- Microsoft Entra ID

### Pricing model basics
- Pricing tiers (Basic, Standard, Premium)
- Pay for storage and operations
- Additional cost for geo-replication in higher tiers

### Common use cases
- Storing container images for Azure workloads
- CI/CD pipelines with Azure DevOps
- Deployments to AKS

---

## 4. Comparison Table

| Cloud Provider | Service Name | Artifact Types | Key Features | Integrations |
|---|---|---|---|---|
| AWS | Amazon ECR | Docker / OCI images | IAM, scanning, lifecycle policies | ECS, EKS |
| GCP | Artifact Registry | Images + packages | Multi-format, security scanning | GKE, Cloud Build |
| Azure | ACR | Docker / OCI images | Geo-replication, RBAC | AKS, Azure DevOps |

---

## 5. Analysis

For a multi-cloud strategy, Google Artifact Registry is the most flexible solution because it supports a wide range of artifact types, not only container images but also language-specific packages.

However, in practice, companies often use the native registry of each cloud provider due to better integration with their ecosystem. AWS ECR, Azure ACR, and GCP Artifact Registry all provide strong security, scalability, and CI/CD integration.

Therefore, the choice depends on priorities: flexibility favors GCP, while tight integration favors using each cloud’s native service.

---

# Task 2 

## 1. AWS

### Service name
AWS Lambda

### Supported runtimes
- Python
- Node.js
- Java
- Go
- .NET
- Custom runtimes

### Execution model
- Event-driven
- HTTP-triggered via API Gateway

### Cold start characteristics
- Cold starts may occur when functions are not used frequently
- Performance depends on runtime and memory allocation

### Integrations
- API Gateway
- S3
- DynamoDB
- SNS / SQS
- CloudWatch

### Pricing model
- Pay per request
- Pay per execution time (milliseconds)
- Free tier available

### Maximum execution duration
- Up to 15 minutes

### Common use cases
- REST APIs
- Event processing (file uploads, queues)
- Backend for mobile/web apps

---

## 2. GCP

### Service name
Google Cloud Functions / Cloud Run

### Supported runtimes
- Python
- Node.js
- Go
- Java
- .NET

### Execution model
- Event-driven (Cloud Functions)
- HTTP-based (Cloud Run)
- Container-based execution (Cloud Run)

### Cold start characteristics
- Cloud Functions may have cold starts
- Cloud Run generally has better performance due to container reuse

### Integrations
- Cloud Storage
- Pub/Sub
- Firestore
- Cloud Build
- IAM

### Pricing model
- Pay per request
- Pay per compute time
- Free tier available

### Maximum execution duration
- Cloud Functions: up to 60 minutes
- Cloud Run: up to 60 minutes

### Common use cases
- APIs and microservices
- Event-driven processing
- Container-based applications

---

## 3. Azure

### Service name
Azure Functions

### Supported runtimes
- Python
- JavaScript (Node.js)
- C#
- Java
- PowerShell

### Execution model
- Event-driven
- HTTP-triggered
- Timer-based execution

### Cold start characteristics
- Cold starts possible in consumption plan
- Reduced cold start in premium plans

### Integrations
- Azure Event Grid
- Azure Storage
- Azure Service Bus
- Azure DevOps

### Pricing model
- Pay per execution
- Pay per execution time
- Premium plans available

### Maximum execution duration
- Consumption plan: ~5–10 minutes
- Premium plan: longer execution supported

### Common use cases
- APIs
- Automation tasks
- Event-driven workflows

---

## 4. Comparison Table

| Cloud | Service | Execution Model | Languages | Max Duration | Pricing |
|---|---|---|---|---|---|
| AWS | Lambda | Event + HTTP | Python, JS, Java, etc. | 15 min | per request + time |
| GCP | Cloud Functions / Run | Event + HTTP + containers | Python, JS, Go, etc. | up to 60 min | per request + time |
| Azure | Functions | Event + HTTP | Python, JS, C#, etc. | 5–10 min (consumption) | per execution |

---

## 5. Analysis

For a REST API backend, AWS Lambda is often a strong choice due to its tight integration with API Gateway and mature ecosystem. It provides reliable scaling and good performance for typical API workloads.

Google Cloud Run is also a strong option, especially when container-based flexibility is required. It allows more control over the runtime environment compared to traditional serverless functions.

Azure Functions is a good option for applications already built within the Azure ecosystem, especially when integrated with Azure services.

Overall, AWS Lambda is typically the most straightforward choice for REST APIs, while Cloud Run offers more flexibility.

---

## 6. Reflection

Serverless computing has several advantages:

- No need to manage servers
- Automatic scaling
- Pay only for actual usage
- Faster development and deployment

However, there are also disadvantages:

- Cold start latency
- Execution time limits
- Less control over infrastructure
- Vendor lock-in risk

Serverless is ideal for event-driven and scalable applications, but may not be suitable for long-running or highly specialized workloads.