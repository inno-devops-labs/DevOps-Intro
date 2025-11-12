# 1. Artifact Registries Research
## 1. AWS Elastic Container Registry (ECR)
### 1. Service name: Elastic Container Registry
### 2. Key features:
- **Integration with Amazon Elastic Container Service (Amazon ECS) and Amazon Elastic Kubernetes Service (Amazon EKS)**
- **OCI and Docker support**
- **Amazon ECR public gallery**
- **Uses IAM to control and monitor access**
- **Containers are encrypted in transit and when stored**
- **Integration with CI/CD tools**
### 3. Supported artifact types: Docker images, Open Container Initiative (OCI) images, and OCI compatible artifacts.
### 4. Integration Capabilities: 
- **Integration with Amazon Elastic Container Service (Amazon ECS) and Amazon Elastic Kubernetes Service (Amazon EKS)**
- **Integration with CI/CD tools: GitHub Actions, GitLab CI/CD, Jenkins and others.**
## 2. AWS CodeArtifact
### 1. Service name: CodeArtifact
### 2. Key features: 
- **Fully managed artifact repository for software packages and dependencies**
- **Supports popular package managers like npm, Maven, PyPI, and NuGet**
- **Integrates with AWS IAM**
- **Scales automatically to handle large package sets**
- **Versioning and dependency resolution built-in**
### 3. Supported artifact types: AWS CodeArtifact supports Cargo, generic, Maven, npm, NuGet, PyPI, Ruby, Swift package formats.
### 4. Integration Capabilities:
- **Integrates with AWS CodeBuild, CodePipeline, and CodeDeploy**
- **Compatible with third-party CI/CD tools like Jenkins, GitHub Actions, and GitLab**
- **Authentication using AWS CLI or SDKs**
- **Integration with popular build tools (npm, Maven, pip, NuGet clients)**

## 3. Google Cloud Articaft Registry
### 1. Service name: Google Cloud Articaft Registry
### 2. Key features:
- **Unified service for managing container images and language packages**
- **Supports Docker and OCI container formats**
- **Built-in vulnerability scanning and metadata analysis**
- **Role-based access control via Cloud IAM**
- **Private and public repositories supported**
- **Encryption with Cloud KMS**
- **Cross-region replication**
- **Supports VPC Service Controls for network security**
- **Integrates seamlessly with Google Cloud Build and Cloud Deploy**
### 3. Supported artifact types: 
- **Docker and OCI images**
- **Maven (Java) artifacts**
- **npm (Node.js) packages**
- **PyPI (Python) packages**
- **Go modules**
- **Helm charts**
- **Generic binary packages**
### 4. Integration Capabilities:
- **Integrates with Google Kubernetes Engine (GKE), Cloud Run, and Cloud Functions**
- **Integration with Google Cloud Build and Cloud Deploy for CI/CD**
- **Integration with third-party tools: Jenkins, GitHub Actions, and GitLab CI/CD**
- **Access control via Google Cloud IAM and VPC Service Controls**
- **Security and vulnerability scanning via Container Analysis API**

## 4. Azure Artifact Registries
### 1. Service name: 
- **Azure Container Registry (ACR) — for container images**
- **Azure Artifacts — for package management**
### 2. Key features:
- **Private and public container image repositories (ACR)**
- **Supports Docker and OCI image formats**
- **Integrated with Azure Active Directory (Azure AD) for authentication**
- **Geo-replication across Azure regions**
- **Automated image builds using Azure DevOps or GitHub Actions**
- **Supports Helm charts and OCI artifacts**
- **Vulnerability scanning via Microsoft Defender for Cloud**
- **Azure Artifacts provides hosted feeds for Maven, npm, NuGet, and Python packages**
- **Versioning and dependency management for packages**

### 3. Supported artifact types:
- **Docker and OCI images (ACR)**
- **Helm charts (ACR)**
- **Maven (Java), npm (Node.js), PyPI (Python), and NuGet (.NET) packages (Azure Artifacts)**

### 4. Integration Capabilities
- **Integration with Azure Kubernetes Service (AKS), Azure App Service, and Azure Functions**
- **Integration with Azure DevOps Pipelines and GitHub Actions**
- **Supports Terraform, Jenkins, and other CI/CD tools**
- **Authentication via Azure Active Directory (Azure AD)**
- **Monitoring and auditing via Azure Monitor and Log Analytics**

## 5. For multicloud strategy I would use Google Cloud Artifact Registry. It supports both container images and multiple package formats under a single service, uses standard APIs, and integrates easily with external CI/CD systems like GitHub Actions and Jenkins.

# 2. Serverless Computing Platform Research

## 1. AWS
### 1. Service names:
- **AWS Lambda (primary serverless function platform)**
- **AWS Fargate (serverless containers for ECS/EKS)**
- **AWS App Runner (serverless app hosting for containerized web services)**

## 2. Key features and capabilities
- **Event-driven functions (Lambda) with native triggers (API Gateway, S3, SNS, SQS, DynamoDB streams, CloudWatch events).**
- **Automatic scaling: concurrent executions scale based on incoming requests/events.**
- **Fine-grained resource allocation (memory configurable; CPU scales with memory).**
- **Integrations: API Gateway, ALB, Step Functions, EventBridge, S3, Kinesis, RDS Proxy, Secrets Manager, IAM.**
- **Cold start behavior for certain runtimes and package sizes (improved with provisioned concurrency).**
- **Multiple deployment/package options: zipped function, container image (Lambda supports container images up to a size limit).**
- **Observability: CloudWatch Logs, X-Ray tracing, CloudWatch Metrics.**

## 3. Supported runtimes and languages: 
- **Node.js, Python, Java, Go, Ruby, .NET (C#), PowerShell.**
- **Custom runtimes / provided.al2 for other languages via runtime API.**
- **Container images (OCI) as a packaging option — can run any language/runtime supported inside the container.**

## 2. GCP
### 1. Service names:
- **Cloud Functions (event-driven functions)**
- **Cloud Run (serverless containers; can be invoked via HTTP or events)**

### 2. Key features and capabilities
- **Cloud Functions: event-driven, integrates with Cloud Pub/Sub, Cloud Storage, Firestore, HTTP triggers.**
- **Cloud Run: runs stateless containers, supports HTTP/S requests, autoscaling down to zero, and concurrency settings (multiple requests per container instance).**
- **Fully managed and also available as Cloud Run for Anthos for hybrid clusters.**
- **VPC connector for private networking, IAM-based access control, integrated logging and tracing (Cloud Logging, Cloud Monitoring, Cloud Trace).**

- **Concurrency model: Cloud Run can serve multiple concurrent requests per instance which often results in lower cold-start overhead and cost efficiency compared to single-request-per-instance models.**

### 3. Supported runtimes and languages
- **Cloud Functions: Node.js, Python, Go, Java, .NET, Ruby (varies by generation/version).**
- **Cloud Run: any language/runtime that can be packaged into a container (full flexibility).**

## 3. Azure
### 1. Service names:
- **Azure Functions (serverless functions)**
- **Azure Container Apps (serverless containers for microservices)**
- **Azure Logic Apps (low-code orchestration; serverless workflow)**

### 2. Key features and capabilities
- **Azure Functions: event-driven triggers (HTTP, Event Grid, Service Bus, Blob Storage, Timer), durable functions for stateful workflows, and flexible hosting plans (Consumption, Premium, Dedicated/App Service plan).**

- **Consumption plan: automatic scaling to zero; Premium adds VNET integration, unlimited execution duration, and avoids cold starts; App Service plan for always-on.**

- **Azure Container Apps: run microservices and background jobs with Dapr integration, scale to zero, HTTP and event-based triggers, and revisions/traffic splitting.**

- **Integrations: Azure Event Grid, Service Bus, Storage, API Management, Application Insights for telemetry.**

### 3. Supported runtimes and languages (examples)

- **Azure Functions: C#/.NET, JavaScript/Node.js, Python, Java, PowerShell, TypeScript, custom handlers for other languages.**

- **Azure Container Apps: any runtime packaged as a container image.**


## 4. Analysis: Which serverless platform would you choose for a REST API backend and why?
**For portability and predictable HTTP performance: GCP Cloud Run or Azure Container Apps (container-based serverless) — they let you deploy a standard container image, support concurrency per instance (lower cost and faster request handling), and are easy to port between clouds.**