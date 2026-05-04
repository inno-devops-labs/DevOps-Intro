# Solution

## Task 1

### AWS CodeArtifact 

**AWS CodeArtifact** is a fully managed service designed for secure storage, publishing, and sharing of software packages used throughout the development process.  
It supports a wide range of package formats, including **npm, Maven, PyPI, NuGet, RubyGems, and SwiftPM**.  
**Key Features:**
- Security & Access Control
- Auditing & Visibility
- Amazon EventBridge to automate workflows
- High Availability: Operates across multiple Availability Zones and stores data redundantly in Amazon S3 and DynamoDB  

**Integrations:** It works seamlessly with other AWS developer tools like AWS CodeBuild for automated builds and can act as an upstream proxy to public repositories like Maven Central and PyPI  
**Pricing Model:** CodeArtifact uses a pay-as-you-go model  
**Common Use Cases:**
- On-demand fetching of software packages from public repositories.
- Securely sharing private packages across different teams and AWS accounts within an organization.
- Building automated workflows for package approval and auditing package usage to manage licenses and vulnerabilities


### GCP: Artifact Registry

**Google Cloud's Artifact Registry** (GAR) is a universal artifact management service that has officially replaced Google Container Registry (GCR).  It is designed to be a private, single control plane for all your packages and container image.  
**Supported Artifact Types:** Unlike many other services, GAR is a multi-format registry. It supports Docker/OCI container images, Maven (Java) , npm (Node.js) , PyPI (Python) , Go modules, APT (Debian) , YUM (RPM) , and Kubernetes Helm charts.  
**Key Features:**
- Unified Management: Provides a single tool for managing both containers and language-based packages, simplifying administration.
- Security & Compliance: Offers fine-grained IAM controls and integrates with VPC Service Controls to enforce security perimeters. It uses the Container Analysis API for vulnerability scanning.
- Geo-Replication: Supports multi-region repositories where artifacts are automatically and redundantly distributed across multiple zones within a region, unlike AWS which requires manual setup.  

**Integrations:** It is deeply integrated with Google Kubernetes Engine (GKE) , Cloud Run, and other key GCP services. It also integrates with Cloud Build for CI/CD pipelines and Cloud Audit Logs for monitoring  
**Pricing Model:** You pay for storage ($0.10 per GB per month, with a 0.5 GB monthly free tier) and network egress. Notably, it does not charge for API requests, which can be a significant cost saving for high-volume environments  
**Common Use Cases:**
- Storing and managing container images for deployment on GKE or Cloud Run.
- Creating a secure, centralized repository for all your organization's development artifacts, from Java JARs to Python wheels.
- Managing global deployments with built-in multi-region redundancy, ensuring low-latency pulls for compute clusters around the world.

### Azure: Azure Container Registry (ACR)

**Azure Container Registry** (ACR) is a managed, private registry service for storing and managing container images and related artifacts, built on the Open Container Initiative (OCI) standard.  
**Supported Artifact Types:** While its primary focus is Docker-compatible container images, it also supports OCI image formats and Helm charts  
**Key Features:**
- Geo-Replication: ACR supports geo-replication to manage image replication across multiple Azure regions, enabling global distribution and network-close deployments.
- Security & Access: Integrates with Azure Active Directory (AAD) for role-based access control (RBAC) and suand supports private links, firewalls, and private endpoints for network isolation. Content trust allows for signed images to ensure integrity.
- Integrated Automation: ACR Tasks allow you to build, test, and patch container images directly within the registry as part of a CI/CD pipeline, even supporting on-commit triggers and base image updates.
- Storage Efficiency: Uses manifest digests (SHA-256 hashes) to uniquely identify images, even if they have the same tag, and shares common layers across images to optimize storage.  

**Integrations:** ACR has a deep, native integration with Azure Kubernetes Service (AKS) , Azure DevOps, and Azure Security Center, making it a central part of the container development lifecycle on Azure.  
**Pricing Model:** ACR uses a pay-as-you-go model with various service tiers (Basic, Standard, Premium). The cost depends on the tier, which determines features like geo-replication, storage limits, and webhooks. You pay for storage and data transfer.  
**Common Use Cases:**
- Serving as the dedicated registry for a Kubernetes (AKS) cluster to store and deploy application pods.
- Automating the image build and patching process with ACR Tasks to secure the software supply chain.
- Replicating container images to multiple Azure regions for high-availability, low-latency global application deployments.

## Task 2

### AWS Lambda

**AWS Lambda** is Amazon's foundational serverless compute service: it runs code for backends and workloads without provisioning or managing servers.  
**Supported Languages:** Native runtimes include Java, Go, PowerShell, Node.js, C#, Python, and Ruby; custom runtimes via the Lambda Runtime API broaden language choice.  

**Key Features:**
- Execution models: Event-driven invocations from 200+ AWS services (for example **S3** or **DynamoDB** updates) plus on-demand calls via the Lambda API or **API Gateway**.
- Cold start performance: Cold starts are typically very fast; **Provisioned Concurrency** keeps functions initialized for double-digit-millisecond responses when latency is critical.
- Maximum execution duration: A single invocation can run up to **15 minutes** (900 seconds).

**Integrations:** Deep integration across AWS, including **S3**, **DynamoDB**, **API Gateway**, and **Lambda@Edge** with **CloudFront**; orchestration of longer workflows uses **AWS Step Functions**.  
**Pricing Model:** Pay-as-you-go: no charge while idle; you pay per request and for duration billed in **1 ms** granularity; **Provisioned Concurrency** is billed separately by configured concurrency.  
**Common Use Cases:**
- File processing after uploads to **S3** (images, video, pipelines).
- Real-time pipelines on streams such as **Kinesis**.
- HTTPS APIs paired with **API Gateway**.
- Scheduled jobs using **Amazon EventBridge** (cron-style triggers).


### GCP: Cloud Functions and Cloud Run

**Cloud Functions (2nd gen)** targets small, event-driven functions; **Cloud Run** runs stateless containers serverlessly with broader runtime flexibility. Together they cover lightweight handlers and packaged services.  

**Supported Languages:**
- **Cloud Functions:** Go, Java, .NET, Node.js, PHP, Python, Ruby.
- **Cloud Run:** Any language packaged in a **Linux container** (OCI-compatible images).

**Key Features:**
- **Cloud Functions:** Public **HTTPS** endpoints or event triggers from services such as **Cloud Storage** and **Pub/Sub**.
- **Cloud Run:** HTTPS request handling plus **Cloud Run jobs** for batch-style tasks that run to completion.
- Cold starts: Typical cold starts on HTTP-triggered functions are low hundreds of milliseconds after idle periods; steadily invoked instances stay warm with lower latency.
- Maximum execution duration: **Cloud Functions (2nd gen)** and **Cloud Run** request handling both support timeouts up to **60 minutes**.

**Integrations:** Native ties to **Cloud Storage**, **Pub/Sub**, **Firestore**, **Cloud Scheduler**, **GKE**, and broader GCP tooling.  
**Pricing Model:** Pay-as-you-go for compute (**vCPU-second**, **GiB-second**) and memory/network egress; no API request surcharge in many scenarios; GCP offers usage free tiers depending on SKU.  
**Common Use Cases:**
- Webhooks, small HTTP endpoints, Slack/GitHub integrations, form backends.
- File and event pipelines on **Cloud Storage** and reactive patterns with **Firestore**.
- Serving dynamic sites (for example Express.js on **Cloud Run**).
- Microservices that need richer container customization than Functions alone.


### Azure: Azure Functions

**Azure Functions** is Microsoft's main serverless option for triggers-based code—tight tooling and broad Azure integrations for small units of work at scale.  
**Supported Languages:** C#, Java, JavaScript, PowerShell, F#, Python; custom handlers enable others (for example Rust, Go); **Flex Consumption** widens scenarios.  

**Key Features:**
- Execution model: Trigger-driven—including **HTTP**, **timers**, **Azure Service Bus**, **Cosmos DB** change feeds, plus many other bindings.
- Cold starts: **Premium** plan instances can stay pre-warmed; **Flex Consumption** also targets lower cold latency.
- Limits by plan—**Consumption** default **~5 minutes**, extendable to **10 minutes**; **Premium** typically up to **60 minutes** (**unbounded** when hosted on dedicated App Service); **Flex Consumption** supports long runs (**~60 minutes**).

**Integrations:** First-class connections to **Azure Cosmos DB**, **Event Grid**, **Service Bus**, and **Azure Monitor / Application Insights** for observability.  
**Pricing Model:** **Consumption** bills per invocation (first monthly million free tier on that plan where applicable) and **GB-seconds**; Premium/Flex tiers price pre-warmed capacity and richer features separately.  
**Common Use Cases:**
- Stream/event processing paired with Event Grid or IoT-style feeds.
- Lightweight REST or GraphQL APIs.
- Stateful orchestration via **Durable Functions** with checkpointed workflows.
- Timer-driven maintenance, reporting, and cleanup jobs.
