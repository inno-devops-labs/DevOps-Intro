# 1

1.1 AWS: Amazon Elastic Container Registry, GCP: Artifact Registry, Azure: Azure Container Registry.

1.2  AWS ECR provides private and public repositories with automated vulnerability scanning via Inspector and cross-region replication, GCP Artifact Registry offers multi-format support with unified IAM and customer-managed encryption keys (CMEK), and Azure ACR features geo-replication, automated container building, and integration with Azure Policy.

1.3  AWS ECR primarily supports container images and OCI artifacts, while GCP Artifact Registry supports a broader range including container images, Maven, npm, Python packages, and OS packages, and Azure ACR supports container images, Helm charts, and specialized artifacts like WASM modules and Bicep files.

1.4 AWS ECR integrates natively with AWS IAM for access control and services like AppRunner and EKS, GCP Artifact Registry integrates with Cloud Build, Cloud Run, and GKE using IAM, and Azure ACR integrates with Azure Active Directory and deployment services like ACI.

1.5 

| Feature | AWS ECR | GCP Artifact Registry | Azure ACR |
| :--- | :--- | :--- | :--- |
| **Primary Focus** | Container & OCI Artifacts | Containers + Language/OS Packages | Container & OCI Artifacts |
| **Supported Artifact Types** | Container images, OCI artifacts | Container images, Maven, npm, Python, OS packages (Debian, Ubuntu, etc.) | Container images, Helm charts, WASM modules, Bicep files |
| **Vulnerability Scanning** | Amazon Inspector | Artifact Analysis | Microsoft Defender for Cloud |
| **Replication** | Cross-region replication | Multi-region support | Geo-replication |
| **Access Control** | AWS IAM | GCP IAM | Azure Active Directory |
| **SLA** | 99.9% monthly uptime guarantee | Not publicly specified | 99.9% monthly uptime guarantee |
| **Integration with Native Services** | AppRunner, EKS, CodeBuild, Lambda | Cloud Build, Cloud Run, GKE, Cloud Functions | ACI, AKS, App Service, DevOps |

1.6 For a multi-cloud strategy, I would not choose a single cloud-native registry but instead choose a cloud-agnostic solution like JFrog Artifactory or Harness Universal Artifact Registry, as they provide centralized management, standardized security policies, and synchronization across different cloud environments to avoid vendor lock-in.

# 2

2.1 AWS Lambda is AWS's primary serverless compute service, Azure Functions is Microsoft's equivalent, and Google Cloud Functions is GCP's offering.

2.2 All three services provide event-driven, auto-scaling compute with consumption-based pricing, though Azure Functions offers the richest trigger and binding library, AWS Lambda provides the most mature ecosystem with advanced features like provisioned concurrency, and Google Cloud Functions focuses on simplicity and fast client-side latency 

2.3 AWS Lambda supports Node.js, Python, Java, C#, Go, and Ruby; Azure Functions supports C#, JavaScript, Python, Java, PowerShell, and TypeScript; while Google Cloud Functions supports Node.js, Python, Go, Java, .NET, Ruby, and PHP 

2.4 AWS Lambda charges $0.20 per 1M requests plus compute time, Azure Functions follows a similar pay-per-execution and GB-s model with a free grant of 1M requests and 400,000 GB-s, and Google Cloud Functions offers a more generous free tier of 2M invocations

2.5 AWS Lambda delivers the most stable cold start latency at 100ms-1s with approximately 120 minutes between cold starts, Azure Functions can experience delays up to 5 seconds with cold starts every 40 minutes, and Google Cloud Functions offers the fastest client-side latency at ~70ms

2.6 
| Feature | AWS Lambda | Azure Functions | Google Cloud Functions |
| :--- | :--- | :--- | :--- |
| **Primary Service Name** | AWS Lambda | Azure Functions | Google Cloud Functions (Cloud Run also available) |
| **Primary Use Case** | Event-driven serverless compute | Event-driven serverless with rich bindings | Lightweight event-driven compute |
| **Cold Start Latency** | 100ms – 1s (most stable) | 300ms – 5s (highest variance) | 200ms – 1.5s (fastest client-side) |
| **Max Execution Timeout** | 15 minutes | 5 minutes (Consumption plan) / Unlimited (Premium plan) | 60 minutes (HTTP) / 540 minutes (event-driven) |
| **Memory Range** | 128 MB – 10 GB | 128 MB – 14 GB | 128 MB – 32 GB |
| **Supported Languages** | Node.js, Python, Java, C#, Go, Ruby, PowerShell | C#, JavaScript, Python, Java, PowerShell, TypeScript | Node.js, Python, Go, Java, .NET, Ruby, PHP |
| **Free Tier (Monthly)** | 1M requests + 400,000 GB-s | 1M requests + 400,000 GB-s | 2M invocations + 400,000 GB-s |
| **Pricing Model** | Pay per request + compute duration (GB-s) | Pay per execution + compute duration (GB-s) | Pay per invocation + compute duration (GB-s) |
| **API Gateway Integration** | API Gateway (native) | API Management | Cloud Endpoints / API Gateway |
| **Strengths** | Most mature ecosystem, largest community, consistent performance | Best .NET/Visual Studio integration, richest triggers and bindings | Generous free tier, fast client-side latency, excellent Firebase integration |
| **Weaknesses** | Limited execution timeout (15 min) | Higher cold start variance | Smaller community, fewer third-party integrations |

2.7 I would choose AWS Lambda for a REST API backend because it offers the most consistent low-latency performance with cold starts as low as 100ms, the deepest API Gateway integration, and the largest community and tooling ecosystem to support production-grade API development

2.8 The main advantages are cost efficiency through pay-per-execution pricing (reducing costs by 70-90% compared to always-on servers) and automatic infinite scaling without infrastructure management, while the main disadvantages are cold start latency delays of 100ms to several seconds and significant vendor lock-in risk that makes migrating between providers difficult and costly