# Lab 10 — Cloud Computing Fundamentals

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

## Task 1 — Artifact Registries Research

### 1.1 Cloud Artifact Registry Services

| Cloud Provider | Service Name                      |
| -------------- | --------------------------------- |
| AWS            | Amazon Elastic Container Registry |
| Google Cloud   | Artifact Registry                 |
| Azure          | Azure Container Registry          |

### 1.2 Key Features

**AWS ECR** provides private and public repositories for container images and OCI artifacts. It integrates with AWS IAM, supports lifecycle policies, image replication, and vulnerability scanning through Amazon Inspector.

**GCP Artifact Registry** is a multi-format artifact registry. It supports container images as well as language and OS packages such as Maven, npm, Python, Go, and Debian packages. It integrates with Cloud Build, Cloud Run, GKE, IAM, and KMS/CMEK.

**Azure Container Registry** is Azure’s managed registry for Docker and OCI artifacts. It supports geo-replication, Azure AD authentication, automated image builds through ACR Tasks, and security integration through Microsoft Defender for Cloud.

### 1.3 Supported Artifact Types

| Service               | Supported Artifacts                                               |
| --------------------- | ----------------------------------------------------------------- |
| AWS ECR               | Docker images, OCI container images, Helm charts, OCI artifacts   |
| GCP Artifact Registry | Docker/OCI images, Maven, npm, Python, Go, Debian/Ubuntu packages |
| Azure ACR             | Docker images, OCI images, Helm charts, OCI artifacts             |

### 1.4 Native Cloud Integrations

| Service               | Native Integrations                                               |
| --------------------- | ----------------------------------------------------------------- |
| AWS ECR               | IAM, ECS, EKS, Lambda, App Runner, CodeBuild                      |
| GCP Artifact Registry | IAM, Cloud Build, Cloud Run, GKE, Cloud Functions                 |
| Azure ACR             | Azure AD, AKS, ACI, App Service, Azure DevOps, Microsoft Defender |

### 1.5 Comparison Table

| Feature                | AWS ECR                        | GCP Artifact Registry                    | Azure ACR                        |
| ---------------------- | ------------------------------ | ---------------------------------------- | -------------------------------- |
| Primary Focus          | Container and OCI artifacts    | Multi-format artifact management         | Container and OCI artifacts      |
| Container Images       | Yes                            | Yes                                      | Yes                              |
| Helm Charts            | Yes                            | Yes                                      | Yes                              |
| Language Packages      | Limited                        | Maven, npm, Python, Go                   | Limited                          |
| OS Packages            | Limited                        | Debian/Ubuntu packages                   | Limited                          |
| Vulnerability Scanning | Amazon Inspector               | Artifact Analysis                        | Microsoft Defender for Cloud     |
| Replication            | Cross-region replication       | Regional and multi-regional repositories | Geo-replication                  |
| Access Control         | AWS IAM                        | Google Cloud IAM                         | Azure AD / Microsoft Entra ID    |
| Build Integration      | CodeBuild, CodePipeline        | Cloud Build                              | ACR Tasks, Azure DevOps          |
| Best Fit               | AWS-native container workloads | Multi-format artifact storage            | Azure-native container workloads |

### 1.6 Multi-Cloud Strategy Choice

For a real multi-cloud strategy, I would prefer a cloud-agnostic artifact management solution such as **JFrog Artifactory** instead of relying on only one cloud-native registry.

The reason is that cloud-native registries are excellent inside their own ecosystems, but they increase vendor lock-in. A neutral registry gives centralized artifact management, consistent retention policies, unified security controls, and easier synchronization across AWS, GCP, and Azure.

If I had to choose only from the three cloud providers, I would choose **GCP Artifact Registry** because it supports the widest range of artifact formats, not only container images. This makes it more flexible for mixed projects that include Docker images, backend packages, frontend packages, and OS-level packages.

---

## Task 2 — Serverless Computing Platform Research

### 2.1 Serverless Compute Services

| Cloud Provider | Service Name                |
| -------------- | --------------------------- |
| AWS            | AWS Lambda                  |
| Google Cloud   | Cloud Functions / Cloud Run |
| Azure          | Azure Functions             |

### 2.2 General Comparison

All three platforms provide event-driven compute with automatic scaling and pay-per-use pricing. The main difference is in ecosystem maturity, integrations, execution limits, and operational model.

* **AWS Lambda** has the most mature serverless ecosystem and strong integration with API Gateway, S3, SNS, SQS, DynamoDB, and EventBridge.
* **Azure Functions** has very strong integration with Microsoft services, .NET, Visual Studio, and supports Durable Functions for stateful workflows.
* **Google Cloud Functions** is simple and well-integrated with Google Cloud services, while Cloud Run provides a more container-native serverless model.

### 2.3 Supported Languages

| Platform               | Supported Languages                                    |
| ---------------------- | ------------------------------------------------------ |
| AWS Lambda             | Node.js, Python, Java, Go, Ruby, .NET, custom runtimes |
| Azure Functions        | C#, JavaScript, TypeScript, Python, Java, PowerShell   |
| Google Cloud Functions | Node.js, Python, Go, Java, .NET, Ruby, PHP             |

### 2.4 Pricing Model

| Platform               | Pricing Model                                          |
| ---------------------- | ------------------------------------------------------ |
| AWS Lambda             | Pay per request and execution duration                 |
| Azure Functions        | Pay per execution and GB-second on Consumption plan    |
| Google Cloud Functions | Pay per invocation, compute time, and networking usage |

All three platforms provide a free tier, which makes them convenient for low-traffic applications, prototypes, automation tasks, and event-driven workloads.

### 2.5 Cold Starts and Performance

Cold starts happen when a serverless platform needs to initialize a new function instance before handling a request.

| Platform               | Cold Start Notes                                                       |
| ---------------------- | ---------------------------------------------------------------------- |
| AWS Lambda             | Usually stable, can be reduced with provisioned concurrency            |
| Azure Functions        | Depends heavily on hosting plan; Premium plan reduces cold starts      |
| Google Cloud Functions | Generally good for lightweight functions; Cloud Run gives more control |

Cold starts are especially important for latency-sensitive REST APIs. For background jobs and asynchronous processing, they are usually less critical.

### 2.6 Comparison Table

| Feature                 | AWS Lambda                        | Azure Functions                              | Google Cloud Functions                          |
| ----------------------- | --------------------------------- | -------------------------------------------- | ----------------------------------------------- |
| Primary Use Case        | Event-driven serverless compute   | Event-driven compute with rich bindings      | Lightweight event-driven compute                |
| REST API Integration    | API Gateway                       | API Management / HTTP triggers               | API Gateway / HTTP triggers                     |
| Max Execution Time      | 15 minutes                        | Depends on plan; longer on Premium/Dedicated | Up to 60 minutes for 2nd gen HTTP functions     |
| Cold Start Mitigation   | Provisioned concurrency           | Premium plan / Always Ready instances        | Minimum instances                               |
| Stateful Workflows      | Step Functions                    | Durable Functions                            | Workflows                                       |
| Strongest Ecosystem Fit | AWS-native systems                | Microsoft/.NET systems                       | GCP/Firebase/Cloud Run systems                  |
| Main Strength           | Mature ecosystem and integrations | Rich triggers and bindings                   | Simplicity and container/serverless flexibility |
| Main Weakness           | Vendor lock-in and timeout limit  | Cold starts on Consumption plan              | Smaller ecosystem than AWS                      |

### 2.7 REST API Backend Choice

For a REST API backend, I would choose **AWS Lambda with API Gateway**.

Reasons:

1. AWS Lambda has a mature production ecosystem.
2. API Gateway integration is well-documented and widely used.
3. Provisioned concurrency can reduce cold-start impact for latency-sensitive APIs.
4. IAM, CloudWatch, X-Ray, DynamoDB, SQS, and EventBridge integrations make it convenient for production systems.
5. There is a large community and many established best practices.

For a container-first architecture, I would also consider **Google Cloud Run**, because it provides serverless scaling while allowing the application to be packaged as a normal container.

### 2.8 Serverless Computing Reflection

#### Advantages

Serverless computing provides several important advantages:

* no server management,
* automatic scaling,
* pay-per-use pricing,
* fast deployment,
* built-in high availability,
* good fit for event-driven workloads,
* reduced operational overhead for small teams.

#### Disadvantages

The main disadvantages are:

* cold start latency,
* vendor lock-in,
* execution time limits,
* less control over infrastructure,
* harder debugging and local reproduction,
* possible unpredictable costs at high scale,
* platform-specific configuration and deployment patterns.

### Final Conclusion

Cloud artifact registries and serverless platforms solve different but connected problems in modern cloud infrastructure.

Artifact registries provide a secure place to store and distribute build artifacts, container images, and packages. For cloud-native workloads, AWS ECR, GCP Artifact Registry, and Azure ACR are all strong choices inside their own ecosystems. For multi-cloud environments, a cloud-agnostic registry is usually more flexible.

Serverless platforms reduce infrastructure management and are effective for APIs, background jobs, automation, and event-driven processing. AWS Lambda is my preferred option for a production REST API because of its maturity, ecosystem, and API Gateway integration, while Azure Functions and Google Cloud Functions are also strong choices depending on the existing cloud stack.
