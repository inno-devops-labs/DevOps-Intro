# Lab 10 Submission: Cloud Service Comparison

## Task 1 — Artifact Registries Research

### 1. Service Overview

| Feature | **AWS** | **GCP** | **Azure** |
| :--- | :--- | :--- | :--- |
| **Primary Service(s)** | **Amazon ECR** (Containers)<br>**AWS CodeArtifact** (Packages) | **Google Artifact Registry**<br>(Unified) | **Azure Container Registry** (Containers)<br>**Azure Artifacts** (Packages) |
| **Supported Formats** | **ECR:** Docker, OCI, Helm<br>**CodeArtifact:** Maven, Gradle, npm, twine, pip, NuGet, Swift | Docker, Maven, npm, Python (pip), Apt, Yum, Go, Helm, Kubeflow | **ACR:** Docker, OCI, Helm<br>**Artifacts:** NuGet, npm, Maven, Python, Gradle |
| **Key Features** | Immutable image tags, image scanning, cross-region replication. Deep IAM integration. | **Unified single interface** for all artifact types. Vulnerability scanning, native GKE/Cloud Run integration. | Geo-replication, ACR Tasks (build/patch in cloud), Docker Content Trust. |
| **Pricing Model** | **ECR:** Storage ($0.10/GB) + Data Transfer.<br>**CodeArtifact:** Storage + Request count ($0.05/10k reqs). | Storage ($0.10/GB) + Data Transfer (Network egress). | **ACR:** Tiered daily rate (Basic/Standard/Premium).<br>**Artifacts:** First 2GB free, then per GB. |

### 2. Analysis

**Integration & Strategy:**
*   **AWS** and **Azure** treat container images and software packages (like npm/maven) as separate concerns, splitting them into two distinct services (ECR vs CodeArtifact, ACR vs Azure Artifacts). This requires managing two sets of permissions and endpoints.
*   **GCP** stands out with a **unified strategy** where *Artifact Registry* handles both containers and language packages in a single service. This simplifies management for multi-language teams.

**Recommendation for Multi-Cloud Strategy:**
I would choose **Google Artifact Registry (GCP)** as the central hub for a multi-cloud strategy. Its support for the widest variety of formats (including OS packages like Apt/Yum) in a single interface reduces administrative overhead. However, if the infrastructure is predominantly AWS, using **ECR** is strictly better for performance due to the lack of data transfer fees within the same region.

---

## Task 2 — Serverless Computing Platform Research

### 1. Service Overview

| Feature | **AWS Lambda** | **Google Cloud Functions** | **Azure Functions** |
| :--- | :--- | :--- | :--- |
| **Supported Runtimes** | Node.js, Python, Java, .NET, Go, Ruby, Custom (via Docker) | Node.js, Python, Go, Java, Ruby, .NET, PHP | .NET, Node.js, Java, Python, PowerShell, Custom Handlers |
| **Execution Model** | Event-driven (S3, DynamoDB, API Gateway, SQS) | Event-driven (HTTP, Cloud Storage, Pub/Sub, Firestore) | Event-driven (HTTP, Blob Storage, CosmosDB, Event Grid) |
| **Timeout Limits** | **15 minutes** (900s) hard limit. | **Gen 1:** 9 mins.<br>**Gen 2:** 60 mins (HTTP only). | **Consumption:** 5-10 mins.<br>**Premium:** Unbounded (technically guaranteed 60m+). |
| **Cold Start Mitigation**| **Provisioned Concurrency:** Keeps initialized instances ready. | **Min Instances:** Keeps a minimum number of instances warm. | **Premium Plan:** Uses pre-warmed workers to avoid cold starts. |
| **Pricing Model** | Per Request ($0.20/1M) + Duration (GB-seconds). | Per Invocation + Compute Time (vCPU/GB-seconds) + Network. | **Consumption:** Per execution + GB-s.<br>**Premium:** Reserved instances (fixed cost). |

### 2. Analysis

**Performance & Use Cases:**
*   **AWS Lambda** is the industry standard with the most mature ecosystem. Its 15-minute timeout is consistent, but it forces an architectural split: anything longer must go to AWS Fargate or Step Functions.
*   **Azure Functions** shines in enterprise environments, offering the best integration with .NET/C# and Visual Studio. Its "Premium Plan" allows for virtually unlimited execution time, blurring the line between serverless and PaaS.
*   **Google Cloud Functions** (Gen 2) is built on Cloud Run (Knative), allowing for much longer execution times (up to 60 mins) for HTTP workloads, making it excellent for heavier data processing tasks.

**Recommendation for REST API Backend:**
I would choose **AWS Lambda** coupled with **API Gateway**.
*   **Why:** It has the fastest cold-start times (generally) for lightweight APIs and the most robust "trigger" ecosystem. The separation of the API layer (Gateway) from the Compute layer (Lambda) allows for sophisticated traffic management, throttling, and authorization handling that is well-documented and widely supported.

### 3. Reflection on Serverless

**Advantages:**
1.  **No Ops:** No server management, OS patching, or scaling configuration required.
2.  **Cost Efficiency:** Scale-to-zero means you pay $0 when no one is using the service.
3.  **Auto-scaling:** Handles sudden traffic spikes automatically without pre-provisioning.

**Disadvantages:**
1.  **Cold Starts:** Initial latency when a function triggers after being idle can impact user experience.
2.  **Vendor Lock-in:** Code often relies on proprietary triggers (e.g., S3 events vs Blob Storage triggers), making migration difficult.
3.  **Debugging Complexity:** Local testing is often an approximation; debugging distributed traces across micro-functions is harder than monolithic debugging.
