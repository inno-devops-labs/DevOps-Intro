# Lab 10 — Submission

## Task 1 — Artifact Registries Research
### AWS Artifact Registry
- Service name: AWS Elastic Container Registry (ECR)

- Supported artifacts:
  - Container images (Docker)

- Key features:
  - Integration with AWS IAM (access control)
  - Image scanning for vulnerabilities
  - Lifecycle policies for image cleanup
  - High availability and scalability

- Integration:
  - ECS (Elastic Container Service)
  - EKS (Elastic Kubernetes Service)
  - CodePipeline / CI/CD

- Pricing:
  - Pay for storage and data transfer


### GCP Artifact Registry
- Service name: Google Artifact Registry

- Supported artifacts:
  - Docker images
  - Maven packages
  - npm packages
  - Python packages

- Key features:
  - Multi-format support
  - Regional repositories
  - Built-in vulnerability scanning
  - Fine-grained IAM permissions

- Integration:
  - Google Kubernetes Engine (GKE)
  - Cloud Build
  - Cloud Run

- Pricing:
  - Pay for storage and network usage

### Azure Artifact Registry
- Service name: Azure Container Registry (ACR)

- Supported artifacts:
  - Docker container images
  - Helm charts

- Key features:
  - Geo-replication
  - Private registry
  - Image scanning
  - Integration with Azure AD

- Integration:
  - Azure Kubernetes Service (AKS)
  - Azure DevOps
  - GitHub Actions

- Pricing:
  - Tier-based pricing (Basic, Standard, Premium)

## Comparison Table

| Feature                | AWS ECR              | GCP Artifact Registry     | Azure ACR              |
|-----------------------|----------------------|----------------------------|------------------------|
| Artifact types        | Docker only          | Multi-format               | Docker + Helm          |
| Security              | IAM + scanning       | IAM + scanning             | Azure AD + scanning    |
| Geo-replication       | Limited              | Regional                   | Strong                 |
| CI/CD integration     | AWS tools            | GCP tools                  | Azure + GitHub         |


## Analysis
GCP Artifact Registry is the most flexible because it supports multiple artifact types.

AWS ECR is simple and well integrated with AWS ecosystem.

Azure ACR provides strong enterprise features like geo-replication.

For a multi-cloud strategy, GCP Artifact Registry is the most flexible choice because it supports multiple artifact formats, reducing the need for separate tools and simplifying cross-platform workflows.


## Task 2 — Serverless Computing Platform Research
### AWS Serverless

- Service name: AWS Lambda

- Supported runtimes:
  - Python, Node.js, Java, Go, .NET

- Execution model:
  - Event-driven
  - HTTP (via API Gateway)

- Key features:
  - Automatic scaling
  - Integration with AWS services (S3, DynamoDB, etc.)
  - No server management
  - Built-in monitoring (CloudWatch)

- Performance:
  - Cold starts may occur
  - Fast scaling

- Pricing:
  - Pay per request + execution time

- Max execution time:
  - 15 minutes

### GCP Serverless
- Service name:
  - Cloud Functions
  - Cloud Run

- Supported runtimes:
  - Python, Node.js, Go, Java, .NET, containers (Cloud Run)

- Execution model:
  - Event-driven
  - HTTP-triggered

- Key features:
  - Fully managed
  - Strong container support (Cloud Run)
  - Integration with GCP services

- Performance:
  - Better cold start performance (Cloud Run)
  - Fast autoscaling

- Pricing:
  - Pay per request + compute time

- Max execution time:
  - Up to 60 minutes (Cloud Run)

### Azure Serverless
- Service name: Azure Functions

- Supported runtimes:
  - Python, Node.js, C#, Java

- Execution model:
  - Event-driven
  - HTTP-triggered

- Key features:
  - Integration with Azure services
  - Durable Functions (long workflows)
  - Auto scaling

- Performance:
  - Cold start exists
  - Good integration with Microsoft ecosystem

- Pricing:
  - Pay per execution + time

- Max execution time:
  - Up to 60 minutes (depending on plan)

## Comparison Table

| Feature            | AWS Lambda        | GCP (Cloud Run / Functions) | Azure Functions     |
|--------------------|------------------|------------------------------|---------------------|
| Model              | Functions        | Functions + Containers       | Functions           |
| Languages          | Many             | Many + containers            | Many                |
| Cold start         | Yes              | Lower (Cloud Run)            | Yes                 |
| Max execution      | 15 min           | Up to 60 min                 | Up to 60 min        |
| Integration        | AWS ecosystem    | GCP ecosystem                | Azure ecosystem     |
| Pricing            | Per request      | Per request                  | Per request         |

## Analysis
For a REST API backend, AWS Lambda is a strong choice due to its simplicity and tight integration with API Gateway.

However, GCP Cloud Run is more flexible because it supports containers, allowing more control over the runtime environment.

Azure Functions is a good choice for projects integrated with Microsoft services.

Overall, GCP Cloud Run is the most flexible option for modern backend development.

## Reflection
Advantages of serverless:
- No server management
- Automatic scaling
- Pay only for usage

Disadvantages:
- Cold start latency
- Limited execution time
- Vendor lock-in

Serverless is ideal for event-driven architectures and microservices, but it may not be suitable for long-running or latency-sensitive applications.