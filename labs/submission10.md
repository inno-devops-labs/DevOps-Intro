# Lab 10 - Cloud Computing Fundamentals

I compared artifact registries and serverless platforms in AWS, GCP, and Azure. I used official documentation and focused on the main practical differences, not on every small feature.

Note: I did not compare exact prices because they can change. I only compared the pricing model and the general use case.

## Task 1 - Artifact Registries

### AWS

AWS is a little different from GCP and Azure because it uses two main services:

- Amazon ECR for container images and OCI artifacts
- AWS CodeArtifact for software packages like npm, Maven, PyPI, and NuGet

Main points:

- ECR is good for Docker images and Kubernetes or ECS workflows
- CodeArtifact is good for internal package repositories
- both services use AWS IAM for access control
- ECR supports image scanning and replication
- CodeArtifact works with common package managers and can use upstream public repos

Pricing model:

- ECR: pay for storage and data transfer
- CodeArtifact: pay for storage, requests, and data transfer

Integrations:

- ECR: ECS, EKS, EC2, CI/CD in AWS
- CodeArtifact: npm, Maven, pip, NuGet, and AWS developer tools

### GCP

The main service in GCP is Artifact Registry.

Main points:

- one service for different artifact types
- supports Docker/OCI images, Maven, npm, Python, Apt, Yum, Go, and generic artifacts
- uses IAM permissions
- can work with vulnerability scanning
- integrates well with Cloud Build, GKE, and Cloud Run

Pricing model:

- mainly based on storage, network traffic, and optional scanning

Integrations:

- Cloud Build
- GKE
- Cloud Run
- other Google Cloud services

### Azure

The main service in Azure is Azure Container Registry (ACR).

Main points:

- private registry for container images and OCI artifacts
- supports Docker images, OCI artifacts, and Helm charts in OCI format
- has geo-replication in higher tiers
- integrates with Azure security and networking features
- works especially well with AKS

Pricing model:

- tier-based pricing: Basic, Standard, Premium
- extra storage is billed separately

Integrations:

- AKS
- App Service
- Azure networking and identity services

### Comparison Table


| Cloud | Main service                  | Supported artifacts                                                 | Key features                                         | Integrations                               | Pricing model                                          |
| ----- | ----------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------ |
| AWS   | Amazon ECR + AWS CodeArtifact | ECR: Docker/OCI images; CodeArtifact: npm, Maven, PyPI, NuGet, etc. | IAM, scanning, replication, package repo support     | ECS, EKS, EC2, package managers, AWS CI/CD | Storage + transfer, and for CodeArtifact also requests |
| GCP   | Artifact Registry             | Docker/OCI, Maven, npm, Python, Apt, Yum, Go, generic               | One service for many formats, IAM, scanning support  | Cloud Build, GKE, Cloud Run                | Storage + transfer + optional scanning                 |
| Azure | Azure Container Registry      | Docker/OCI images, Helm/OCI artifacts                               | Private registry, geo-replication, Azure integration | AKS, App Service, Azure services           | Tier-based + extra storage                             |


### Which registry would I choose for multi-cloud?

I would choose GCP Artifact Registry.

My reason is simple: it gives one service for many artifact types. That is easier to understand and manage in a multi-cloud setup. AWS is also strong, but there I need both ECR and CodeArtifact. Azure ACR is good, but it is more focused on container artifacts.

## Task 2 - Serverless Computing Platforms

### AWS

The main serverless compute service in AWS is AWS Lambda.

Main points:

- event-driven platform
- supports common runtimes like Node.js, Python, Java, .NET, and others
- works with API Gateway and many AWS event sources
- cold starts can happen, especially for larger functions
- pricing is based on requests and execution time
- maximum execution time is up to 15 minutes

Common use cases:

- automation
- file processing
- queue processing
- small APIs

### GCP

In GCP, the main serverless options are Cloud Run and Cloud Run functions.

Main points:

- Cloud Run is good for containers and web services
- Cloud Run functions is the function-style option
- supports common languages, and Cloud Run can run any container
- works for HTTP requests and event-driven tasks
- can scale to zero, but also supports concurrency
- pricing is based on requests and used CPU/memory time
- Cloud Run service timeout can be up to 60 minutes

Common use cases:

- REST APIs
- webhooks
- microservices
- background jobs

### Azure

The main serverless compute service in Azure is Azure Functions.

Main points:

- event-driven platform with many triggers
- supports C#, Java, JavaScript/TypeScript, Python, PowerShell, and others
- strong integration with Azure services
- cold starts can happen on consumption plans
- Premium plan helps reduce cold starts
- pricing depends on the hosting plan
- HTTP response time has a practical limit of about 230 seconds

Common use cases:

- automation
- timers
- queue and message processing
- Azure-based workflows

### Comparison Table


| Cloud | Main service                    | Model                             | Runtimes                                        | Performance notes                                   | Pricing model              | Main limit                                     |
| ----- | ------------------------------- | --------------------------------- | ----------------------------------------------- | --------------------------------------------------- | -------------------------- | ---------------------------------------------- |
| AWS   | Lambda                          | Function as a Service             | Node.js, Python, Java, .NET, and more           | Cold starts are possible                            | Requests + execution time  | Up to 15 minutes                               |
| GCP   | Cloud Run / Cloud Run functions | Serverless containers + functions | Common runtimes, and any container in Cloud Run | Can scale to zero, supports concurrency             | Requests + CPU/memory time | Up to 60 minutes request timeout for Cloud Run |
| Azure | Azure Functions                 | Function as a Service             | C#, Java, JS/TS, Python, PowerShell, and more   | Cold starts on consumption plans, better on Premium | Depends on plan and usage  | About 230 seconds for HTTP response            |


### Which platform would I choose for a REST API backend?

I would choose Google Cloud Run.

For a REST API, Cloud Run looks the most convenient to me because I can package the app in a container and use any framework I want. It also supports concurrency, so it feels closer to a normal backend service than a classic function-only model.

Lambda is also a good option, especially inside AWS, but Cloud Run looks simpler for a standard web API. Azure Functions is useful too, but I think it fits event-driven Azure projects better than a typical REST backend.

### Main advantages and disadvantages of serverless

Advantages:

- no need to manage servers
- automatic scaling
- good for uneven traffic
- easy to connect with cloud events and managed services

Disadvantages:

- cold starts
- time and memory limits
- stronger vendor lock-in
- debugging can be harder than in a simple server setup

## Sources

### AWS

1. Amazon ECR overview
  [https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
2. Amazon ECR pricing
  [https://aws.amazon.com/ecr/pricing/](https://aws.amazon.com/ecr/pricing/)
3. AWS CodeArtifact packages overview
  [https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html](https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html)
4. AWS CodeArtifact pricing
  [https://aws.amazon.com/codeartifact/pricing/](https://aws.amazon.com/codeartifact/pricing/)
5. AWS Lambda overview
  [https://docs.aws.amazon.com/lambda/latest/dg/welcome.html](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
6. AWS Lambda quotas
  [https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)

### Google Cloud

1. Artifact Registry overview
  [https://cloud.google.com/artifact-registry/docs/overview](https://cloud.google.com/artifact-registry/docs/overview)
2. Artifact Registry pricing
  [https://cloud.google.com/artifact-registry/pricing](https://cloud.google.com/artifact-registry/pricing)
3. Cloud Run overview
  [https://cloud.google.com/run/docs/overview/what-is-cloud-run](https://cloud.google.com/run/docs/overview/what-is-cloud-run)
4. Cloud Run pricing
  [https://cloud.google.com/run/pricing](https://cloud.google.com/run/pricing)
5. Cloud Run quotas and limits
  [https://cloud.google.com/run/quotas](https://cloud.google.com/run/quotas)

### Azure

1. Azure Container Registry documentation
  [https://learn.microsoft.com/en-us/azure/container-registry/](https://learn.microsoft.com/en-us/azure/container-registry/)
2. Azure Container Registry pricing
  [https://azure.microsoft.com/en-us/pricing/details/container-registry/](https://azure.microsoft.com/en-us/pricing/details/container-registry/)
3. Azure Functions overview
  [https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)
4. Azure Functions scale and hosting
  [https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale)
5. Azure Functions pricing
  [https://azure.microsoft.com/en-us/pricing/details/functions/](https://azure.microsoft.com/en-us/pricing/details/functions/)

