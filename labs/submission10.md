# Lab 10 - Cloud Computing Fundamentals

## Task 1 - Artifact Registries

### Services

| Cloud provider | Service name | Supported artifacts | Main features |
| --- | --- | --- | --- |
| AWS | Amazon Elastic Container Registry (ECR) | Docker images, OCI images, OCI artifacts | Private repositories, IAM access, image scanning, lifecycle rules, replication, integration with ECS, EKS and Lambda |
| Google Cloud | Artifact Registry | Docker, Maven, npm, Python, Apt, Yum, Go, Helm and generic artifacts | Many artifact formats, IAM, vulnerability scanning, remote repositories, virtual repositories, integration with Cloud Build, GKE and Cloud Run |
| Azure | Azure Container Registry (ACR) | Docker images, OCI images, OCI artifacts and Helm charts | Private registry, Azure RBAC, geo-replication in Premium tier, ACR Tasks, integration with AKS and Azure DevOps |

### Short Analysis

I would choose Google Cloud Artifact Registry for a multi-cloud strategy. It supports more artifact types than ECR and ACR, so one service can store both container images and application packages. This is useful when different teams use different languages and tools.

AWS ECR is better if the project is mostly inside AWS. Azure ACR is better if the project uses AKS and Azure DevOps. But for a general multi-cloud case, Google Artifact Registry is the most flexible option.

## Task 2 - Serverless Computing Platforms

### Comparison Table

| Cloud provider | Service name | Key features | Supported runtimes / languages | Pricing model | Performance |
| --- | --- | --- | --- | --- | --- |
| AWS | AWS Lambda | Event-driven functions, API Gateway integration, many AWS triggers, automatic scaling | Node.js, Python, Java, .NET, Go, Ruby, custom runtimes and container images | Pay per request and execution time | Can have cold starts. Maximum execution time is 15 minutes. Provisioned Concurrency can reduce cold starts. |
| Google Cloud | Cloud Run and Cloud Run functions | Serverless containers, HTTP services, events with Eventarc, scale to zero, easy container deployment | Cloud Run can use any language in a container. Functions support Node.js, Python, Go, Java, Ruby, PHP and .NET | Pay for CPU, memory, requests and networking | Good for REST APIs. Can scale to zero. Minimum instances can reduce cold starts. Cloud Run requests can run up to 60 minutes. |
| Azure | Azure Functions | HTTP triggers, queue triggers, timer triggers, Event Grid, Service Bus, Durable Functions | C#, JavaScript/TypeScript, Python, Java, PowerShell and custom handlers | Pay per execution and memory time on Consumption/Flex plans | Cold starts are possible on Consumption plan. Premium and always-ready instances reduce cold starts. Classic Consumption has a short timeout. |

### Which Platform I Would Choose for a REST API

I would choose Google Cloud Run for a REST API backend. A REST API is usually a normal web service with many routes, so it fits well into a container. Cloud Run allows using common frameworks like Express, FastAPI, Spring Boot or ASP.NET. It also supports concurrency, scales to zero, and does not force the project to be split into many small functions.

AWS Lambda is also good for small APIs, but API Gateway adds extra setup and cost. Azure Functions is good for Azure-based projects, but the hosting plan must be chosen carefully because it affects cold starts and time limits.

### Advantages of Serverless

- No need to manage servers.
- Automatic scaling.
- Pay only for real usage.
- Good for small APIs, background jobs and event processing.
- Easy integration with cloud services.

### Disadvantages of Serverless

- Cold starts can make the first request slower.
- Debugging can be harder than in a normal server.
- Cloud provider lock-in is possible.
- Time limits can be a problem for long tasks.
- Cost can be hard to predict if traffic grows fast.

## Sources

- AWS ECR: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
- Google Artifact Registry: https://cloud.google.com/artifact-registry/docs/overview
- Azure Container Registry: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro
- AWS Lambda: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Google Cloud Run: https://cloud.google.com/run/docs/overview/what-is-cloud-run
- Azure Functions: https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview
