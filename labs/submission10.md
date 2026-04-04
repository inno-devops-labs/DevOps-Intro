# Task 1

Task 1 covers artifact registry services on AWS, Google Cloud, and Azure. Registries store container images and other build artifacts so CI/CD and runtimes can pull consistent versions.

## AWS - Amazon Elastic Container Registry (ECR)

AWS’s primary registry is **Amazon ECR**. Documentation describes it as focused on container images and OCI artifacts. It supports Docker images, OCI images, and Helm charts stored as OCI artifacts. It also has useful security features such as vulnerability scanning and access control through AWS IAM. Another important feature is replication across regions and accounts. ECR integrates very well with other AWS services such as ECS, EKS, and CI/CD pipelines. In terms of pricing, it is mostly based on how much data is stored and transferred.

## GCP - Artifact Registry

On Google Cloud the main product is **Artifact Registry**. Compared with the other two, it is the broadest: besides container images it also supports package formats such as npm, Maven, Python, APT, and YUM. This makes it useful not only for containers but also for general dependency management. It includes IAM-based access control, cleanup policies, and vulnerability scanning. It also integrates well with Cloud Build, GKE, and Cloud Run. Its pricing is also based mainly on storage and network usage.

## Azure - Azure Container Registry (ACR)

For Azure, the main service is Azure Container Registry, or ACR. Like Amazon ECR, it is strongly focused on container and OCI artifacts. It supports Docker images, OCI artifacts, and Helm charts as OCI artifacts. ACR includes access control, automation features through ACR Tasks, and geo-replication in the Premium tier. It integrates well with Azure services such as AKS and App Service. Its pricing is based on service tiers such as Basic, Standard, and Premium.

## Comparison

All three support container image storage, security-related features, and tight integration with the same vendor’s stack. The main split is that **Artifact Registry** covers more **package types**, while **ECR** and **ACR** stay **container-first**.

**Pricing comparison (artifact registries):** Storage and **egress** show up everywhere. **ECR** and **Artifact Registry** look closer to **pay-for-usage** (GB-months + transfer; GCP may add small per-operation charges). **ACR** adds a **fixed SKU** (Basic / Standard / Premium) with included storage, overage, and extra cost for options such as **geo-replication** on Premium—more predictable per month, less “only pay per byte”.

Comparison table:


| Provider | Service                  | Main Support                             | Key Strengths                                 | Pricing (how you are charged)                                                                  |
| -------- | ------------------------ | ---------------------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| AWS      | Amazon ECR               | Docker, OCI images, Helm OCI             | Strong AWS integration, replication, scanning | Storage (GB-month); data transfer (pull/cross-region/internet); optional paid scanning add-ons |
| GCP      | Artifact Registry        | Containers, npm, Maven, Python, APT, YUM | Broad package support, cleanup policies       | Storage; outbound network (egress); operation-based fees in some cases; varies by format       |
| Azure    | Azure Container Registry | Docker, OCI images, Helm OCI             | Geo-replication, ACR Tasks, Azure integration | Monthly tier fee + included storage; overage storage; outbound data; geo-replication (Premium) |

### Representative published prices — artifact registries (USD)

Figures below are taken from each vendor’s **public pricing** pages (checked **April 2026**). **Region, currency, discounts, and taxes** can change the bill; use the linked pricing pages or each cloud’s calculator before making decisions.

| Service | What the vendor publishes (summary) |
| -------- | ----------------------------------- |
| **Amazon ECR** | **Storage:** **$0.10 per GB-month** for data stored in private or public repositories. **Free usage:** **500 MB/month** of private registry storage for new accounts for **12 months** (AWS Free Tier); **50 GB/month** storage for public repos is **always free** for all customers. **Data transfer:** pulls to **EC2, Lambda, Fargate, App Runner in the same Region** are **$0/GB**; **cross-Region / internet** egress follows **AWS data transfer** tiers (AWS illustrates cross-Region pulls on the order of **~$0.09/GB** in their examples — exact tier depends on path and volume). Source: [Amazon ECR pricing](https://aws.amazon.com/ecr/pricing/). |
| **Artifact Registry (GCP)** | **Storage:** **first 0.5 GB/month free**, then **$0.10 per GB-month** (same rate for regional and multi-regional repos). **Ingress** to Google Cloud is **free**; **egress** to other Google Cloud locations ranges from **$0** (same location / many same-continent cases) up to about **$0.01–$0.15/GB** depending on source/destination; **internet egress** follows **Premium network tier** rates. Source: [Artifact Registry pricing](https://cloud.google.com/artifact-registry/pricing). |
| **Azure Container Registry** | Pricing is a **per-day SKU** plus possible **overage** for storage beyond what the tier includes. Microsoft documents **included storage** as **10 GiB (Basic)**, **100 GiB (Standard)**, **500 GiB (Premium)** per registry. **Typical US Pay-As-You-Go list prices** shown in the Azure pricing experience are often around **~$0.167/day (Basic)**, **~$0.667/day (Standard)**, **~$1.668/day (Premium)** (roughly **~$5 / ~$20 / ~$50** if you multiply by ~30 — confirm in the portal). **Geo-replication** and **bandwidth** are billed separately. Sources: [ACR SKU limits](https://learn.microsoft.com/azure/container-registry/container-registry-skus), [Azure Container Registry pricing](https://azure.microsoft.com/pricing/details/container-registry/). |

## Analysis

For a **multi-cloud** or polyglot setup, **Artifact Registry** is the easiest to justify: the same service can hold containers **and** language packages, which shows up often in real repos. If workloads already sit mostly on **AWS** or **Azure**, **ECR** or **ACR** is usually less friction because IAM, pipelines, and Kubernetes integrations are already aligned with that cloud.

# Task 2

Task 2 compares serverless compute on AWS, GCP, and Azure—run code without managing servers, with scaling handled by the platform.

## AWS - AWS Lambda

For AWS, the main serverless service is AWS Lambda. Lambda is event-driven and can run code in response to many triggers, such as HTTP requests, file uploads, queue messages, or database events. It supports multiple programming languages and also allows custom runtimes. Lambda has a maximum execution time of 15 minutes. One issue with Lambda is cold starts, but AWS provides features such as Provisioned Concurrency and SnapStart to reduce startup delay. Pricing is based mainly on the number of requests and execution time.

## GCP - Cloud Run

On GCP the comparison uses **Cloud Run** (not only Cloud Functions) because it is **container-based**: ship a container image and run it as a service. It supports HTTP services and event-driven workloads. Cloud Run allows more flexibility than a classic function-only platform because it can run almost any containerized application. It supports request timeouts up to 60 minutes. Cold starts still exist, but Google allows minimum instances to reduce them. Pricing is based on requests, CPU, and memory usage.

## Azure - Azure Functions

For Azure, the main service is Azure Functions. It supports several languages, including C#, Python, Java, JavaScript, and others. Like AWS Lambda, it is event-driven and can also handle HTTP requests, timers, and queue-based triggers. Azure Functions has different hosting plans, so some limits depend on the selected plan. One important point is that HTTP-triggered functions have a practical response limit because of Azure Load Balancer timeout behavior. Cold starts may also happen, but Azure has always-ready or prewarmed instances in some plans. Pricing depends on the hosting model, but in general it follows pay-per-use logic.

## Comparison

**Pricing comparison (serverless):** **Lambda** and **Azure Functions (Consumption)** line up as **per invocation + compute time** (GB-seconds, and vCPU-seconds where applicable). **Cloud Run** adds **per request** and **vCPU/RAM time** for active containers, plus **minimum instances** if configured. **Azure Functions** also has **Premium** and **App Service**-backed plans with **reserved capacity**, which changes the curve versus pure consumption.

Serverless comparison table:


| Provider | Service         | Execution Model                           | Max Duration                 | Cold Start Solutions               | Pricing (how you are charged)                                                                                                       |
| -------- | --------------- | ----------------------------------------- | ---------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| AWS      | AWS Lambda      | Event-driven, HTTP through integrations   | 15 minutes                   | Provisioned Concurrency, SnapStart | Per million requests + duration (GB-s); optional Provisioned Concurrency (steady fee); free tier                                    |
| GCP      | Cloud Run       | HTTP and event-driven containers          | Up to 60 minutes per request | Minimum instances                  | Requests + vCPU-seconds + GiB-seconds while serving; min instances billed 24/7 if set; free monthly use allowance                   |
| Azure    | Azure Functions | Event-driven, HTTP, timer, queue triggers | Depends on plan              | Always-ready / prewarmed instances | Consumption: executions + GB-s (and related compute units); Premium/App Service: base fee + usage; partial free tier on Consumption |

### Representative published prices — serverless compute (USD)

Same caveat as above: **region, plan, and offers** matter; numbers are from **vendor list prices** as of **April 2026**.

| Service | What the vendor publishes (summary) |
| -------- | ----------------------------------- |
| **AWS Lambda** (on-demand, **x86**, first duration tier — e.g. **US East N. Virginia**) | **$0.20 per 1 million requests**. **Compute:** about **$0.0000166667 per GB-second** of configured memory allocation × duration (AWS quotes this rate in their pricing examples for that region/tier). **Free tier (ongoing):** **1 million requests/month** and **400,000 GB-seconds/month** aggregated for x86 and Arm. **Arm/Graviton** has a lower GB-second rate on the same page; duration is billed in **1 ms** increments. Source: [AWS Lambda pricing](https://aws.amazon.com/lambda/pricing/). |
| **Cloud Run** (services with **request-based** billing, **Tier 1** region example **us-central1**) | **CPU (active / billed time):** **$0.000024 per vCPU-second**. **CPU (idle min instances):** **$0.0000025 per vCPU-second**. **Memory:** **$0.0000025 per GiB-second** (active and idle min-instance rows on the same table). **Requests:** **$0.40 per 1 million** requests. **Free tier (monthly, aggregated per billing account):** **2 million requests**, **180,000 vCPU-seconds**, **360,000 GiB-seconds** (for request-based services, using us-central1 free-tier basis in Google’s table). Other regions use **Tier 2/3** rates on Google’s page. Source: [Cloud Run pricing](https://cloud.google.com/run/pricing). |
| **Azure Functions** (**Consumption** plan, Pay-As-You-Go list) | **$0.000016 per GB-second** of execution time and **$0.20 per 1 million executions**. **Free grant per subscription (Consumption):** **1 million executions** and **400,000 GB-seconds** per month (paid subscriptions). **Flex Consumption** on the same page uses different meters (e.g. **$0.000026/GB-s** on-demand execution time, **$0.40 per million** executions in the Flex table). **Premium** plan bills **vCPU** and **memory per month** for always-allocated capacity instead of per-execution GB-s. Source: [Azure Functions pricing](https://azure.microsoft.com/pricing/details/functions/). |

## Analysis

For a **REST API**, **Cloud Run** is a strong default: HTTP is first-class and the unit of deployment is a **container**, so framework choice stays open. **Lambda** is equally solid when the API sits inside an **AWS**-heavy stack (API Gateway, DynamoDB, etc.) but the packaging model is more **function-centric**. **Azure Functions** fits best when the org already standardizes on **Azure** tooling and .NET-style workflows.

## Reflection

Serverless cuts down on **server ops**, scales with traffic, and bills mainly for **use**—good for prototypes and spiky workloads.

Downsides include **cold starts**, **time limits** (e.g. Lambda’s 15-minute cap vs long jobs), trickier **debugging** in event-driven graphs, and **lock-in** because triggers and config differ per cloud.

**Takeaway:** AWS, GCP, and Azure all ship credible services; the differences are mostly **ecosystem fit**. **Artifact Registry** stands out when artifacts are not only images; **Cloud Run** pairs naturally with containerized HTTP APIs, while **ECR + Lambda** or **ACR + Functions** match single-vendor AWS or Azure setups.

## References

**Task 1 — artifact registries**

- [Amazon ECR — What is Amazon ECR?](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [Google Artifact Registry documentation](https://cloud.google.com/artifact-registry/docs)
- [Azure Container Registry documentation](https://learn.microsoft.com/azure/container-registry/)

**Official pricing pages (for numbers and regions)**

- [Amazon ECR pricing](https://aws.amazon.com/ecr/pricing/)
- [Artifact Registry pricing](https://cloud.google.com/artifact-registry/pricing)
- [Azure Container Registry pricing](https://azure.microsoft.com/pricing/details/container-registry/)

**Task 2 — serverless compute**

- [AWS Lambda — What is AWS Lambda?](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Google Cloud Run documentation](https://cloud.google.com/run/docs)
- [Google Cloud Functions documentation](https://cloud.google.com/functions/docs) (GCP’s function-style option alongside Cloud Run)
- [Azure Functions documentation](https://learn.microsoft.com/azure/azure-functions/)

**Official pricing pages**

- [AWS Lambda pricing](https://aws.amazon.com/lambda/pricing/)
- [Cloud Run pricing](https://cloud.google.com/run/pricing)
- [Azure Functions pricing](https://azure.microsoft.com/pricing/details/functions/)

