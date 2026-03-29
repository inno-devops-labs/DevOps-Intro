# Lab 10 Submission

## Task 1 - Artifact Registries Research

### AWS

Service name: `Amazon ECR (Elastic Container Registry)`

Key features:
- Image scanning (security)
- Access control (IAM)
- Tag immutability
- Lifecycle policies
- Replication between regions

Supported artifact types:
- Docker images
- OCI images
- Helm charts (OCI)

Integration capabilities:
- Works with Docker
- Integrates with EKS, ECS, CI/CD tools

Pricing: Pay for storage and data transfer


### GCP

Service name: `Artifact Registry`

Key features:
- Supports many artifact types
- Vulnerability scanning
- Regional repositories
- Virtual and remote repositories
- Access control

Supported artifact types:
- Docker images
- Helm charts
- Maven, npm, Python
- Apt, Yum
- Go modules
- Generic artifacts

Integration capabilities:
- GKE
- Cloud Run
- CI/CD tools

Pricing: Pay for storage, transfer, scanning


### Azure

Service name: `Azure Container Registry (ACR)`

Key features:
- ACR Tasks (auto build)
- Geo-replication (Premium)
- Access control
- Webhooks
- Vulnerability scanning (Defender)

Supported artifact types:
- Container images
- Helm charts
- OCI artifacts

Integration capabilities:
- Azure Kubernetes Service (AKS)
- Azure DevOps

Pricing: Tier-based (Basic, Standard, Premium)


### Comparison table highlighting similarities and differences

| Provider | Service           | Supported formats                      | Security features                  | Geo distribution          | CI/CD integration                   | Pricing                            | Performance & reliability  |
| -------- | ----------------- | -------------------------------------- | ---------------------------------- | ------------------------- | ----------------------------------- | ---------------------------------- | -------------------------- |
| AWS      | ECR               | Docker, OCI, Helm                      | Image scanning, IAM access control | Cross-region replication  | AWS CodeBuild, CodePipeline, Docker | Pay-as-you-go (storage + transfer) | High, managed by AWS       |
| GCP      | Artifact Registry | Docker, Helm, Maven, npm, Python, etc. | Vulnerability scanning, IAM, Binary Authorization        | Regional repositories     | Cloud Build, CI/CD tools            | Pay-as-you-go                      | High, regional reliability |
| Azure    | ACR               | Docker, OCI, Helm                      | Defender scanning, access control  | Geo-replication (Premium) | Azure DevOps, CI/CD tools           | Tier-based                         | High, depends on tier      |


### Analysis: Which registry service would you choose for a multi-cloud strategy and why?

I would choose `GCP Artifact Registry`:
- Supports many artifact types (not only containers)
- More flexible (virtual + remote repositories)
- Good for mixed environments


## Task 2 - Serverless Computing Platform Research

### AWS

Service name: `AWS Lambda`

Key features:
- Auto scaling
- Many event sources
- Integration with AWS services

Supported runtimes:
- Python
- Node.js
- Java
- C#
- Custom runtimes

Execution model:
- Event-driven
- HTTP via API Gateway

Performance:
- Cold starts possible
- SnapStart reduces delay

Limits: Max execution time: 15 minutes

Pricing: Pay per request + execution time


### GCP

Service name: `Cloud Run`

Key features:
- Runs containers
- Auto scaling
- Simple deployment

Supported runtimes:
- Any language (via containers)

Execution model:
- HTTP-based
- Event-driven

Performance:
- Cold starts exist but usually fast

Limits: Up to 60 minutes

Pricing: Pay per request + CPU/memory


### Azure

Service name: `Azure Functions`

Key features:
- Auto scaling
- Many triggers
- Flex Consumption plan

Supported runtimes:
- C#
- Java
- Python
- JavaScript / TypeScript
- PowerShell

Execution model:
- Event-driven
- HTTP triggers

Performance:
- Cold starts possible
- Can use always-ready instances

Limits: Depends on plan

Pricing: Pay per execution (Consumption plan)


### Comparison table highlighting similarities and differences

| Provider | Service   | Language support       | Cold start                    | Execution limit | Scaling      | Triggers            | Pricing                      | Monitoring       |
| -------- | --------- | ---------------------- | ----------------------------- | --------------- | ------------ | ------------------- | ---------------------------- | ---------------- |
| AWS      | Lambda    | Many + custom runtimes | Yes (reduced with SnapStart)  | 15 min          | Auto scaling | Events, API Gateway | Pay per request + time       | CloudWatch       |
| GCP      | Cloud Run | Any (containers)       | Yes (usually low)             | Up to 60 min    | Auto scaling | HTTP, events        | Pay per request + CPU/memory | Cloud Monitoring |
| Azure    | Functions | Many languages         | Yes (reduced in Premium/Flex) | Depends on plan | Auto scaling | Events, HTTP        | Pay per execution            | Azure Monitor    |


### Analysis: Which serverless platform would you choose for a REST API backend and why?

I would choose `GCP Cloud Run`:
- Native HTTP support
- Works like a normal web service
- Supports any language
- Longer execution time


### Reflection: What are the main advantages and disadvantages of serverless computing?

Advantages:
- No server management
- Auto scaling
- Pay only when used
- Easy integration with cloud services

Disadvantages:
- Cold starts
- Execution time limits
- Vendor lock-in
- Less control over environment
- Observability complexity
