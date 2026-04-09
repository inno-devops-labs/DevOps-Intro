# Lab 10 Submission — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

Artifact registries are crucial for storing and managing software packages and container images in a DevOps workflow.

### 1.1 Service Overview

*   **AWS: Amazon ECR & CodeArtifact**
    *   **ECR (Elastic Container Registry):** Stores Docker/OCI container images. Features deep integration with the AWS ecosystem (ECS, EKS), vulnerability scanning, and lifecycle policies.
    *   **CodeArtifact:** A polyglot artifact repository for packages like npm, PyPI, and Maven. Manages dependencies and can pull from public upstream repositories.

*   **GCP: Artifact Registry**
    *   A single, unified service for all artifacts, replacing the older Container Registry.
    *   Supports Docker, Maven, npm, Python, Apt, and Yum formats.
    *   Features include built-in vulnerability scanning, IAM-based access control, and support for regional and multi-regional repositories.

*   **Azure: Azure Container Registry (ACR) & Azure Artifacts**
    *   **ACR:** Stores Docker/OCI container images. Features include geo-replication, security scanning via Microsoft Defender, and Azure AD integration.
    *   **Azure Artifacts:** Part of Azure DevOps, it manages packages like Maven, npm, and NuGet. Supports "upstream sources" to use packages from public registries.

### 1.2 Comparison and Analysis

#### Comparison Table: Artifact Registries

| Feature                  | AWS (ECR + CodeArtifact)                | GCP (Artifact Registry)             | Azure (ACR + Artifacts)                             |
| ------------------------ | --------------------------------------- | ----------------------------------- | --------------------------------------------------- |
| **Service Model**        | Two separate services                   | Single unified service              | Two separate services                               |
| **Supported Formats**    | Docker, OCI, Maven, npm, PyPI, NuGet    | Docker, Maven, npm, PyPI, Apt, Yum  | Docker, OCI, Maven, npm, PyPI, NuGet, Universal Pkg |
| **Vulnerability Scanning** | Yes (ECR Basic/Advanced)                | Yes (Container Analysis)            | Yes (Microsoft Defender for Cloud)                  |
| **Geo-Replication**      | Yes (Cross-Region Replication)          | Yes (Multi-regional repos)          | Yes (Geo-replication)                               |
| **CI/CD Integration**    | AWS CodePipeline, CodeBuild             | Google Cloud Build                  | Azure Pipelines                                     |

#### Analysis: Best Choice for a Multi-Cloud Strategy

For a multi-cloud strategy, **GCP Artifact Registry** is the most compelling choice.

**Reasoning:**

1.  **Unified Service:** It manages all artifact types in one place, simplifying management, permissions, and automation compared to the dual-service approach of AWS and Azure.
2.  **Broader Format Support:** Native support for OS packages like **Apt** and **Yum** is a unique advantage for managing system-level dependencies across different cloud environments.
3.  **Modern Design:** As a newer service, its design is inherently more flexible and centralized.

While any native cloud service introduces some lock-in, GCP's unified model presents the least operational friction for a multi-cloud setup.

---

## Task 2 — Serverless Computing Platform Research

Serverless (FaaS) platforms run code in response to events without requiring server management.

### 2.1 Service Overview

*   **AWS: AWS Lambda**
    *   The market leader and most mature FaaS platform with a vast ecosystem of triggers and integrations.
    *   Supports all major languages (Node.js, Python, Java, Go, .NET, etc.) and custom runtimes.
    *   Features include `Lambda Layers` for sharing code and `Provisioned Concurrency` to eliminate cold starts.
    *   **Max Execution:** 15 minutes.

*   **GCP: Google Cloud Functions**
    *   Known for simplicity and fast startup times.
    *   Now has a 2nd Gen built on Cloud Run, offering longer execution times (up to 60 min), concurrency, and more flexible triggers.
    *   Supports Node.js, Python, Go, Java, .NET, Ruby, and PHP.
    *   **Max Execution:** 9 min (1st Gen), 60 min (2nd Gen).

*   **Azure: Azure Functions**
    *   Offers flexible hosting models: Consumption (pay-per-use), Premium (no cold starts), and App Service (dedicated resources).
    *   Its standout feature is **Durable Functions**, an extension for writing stateful, long-running orchestrations.
    *   Excellent developer experience with Visual Studio/VS Code.
    *   **Max Execution:** 5-10 min (Consumption Plan), unlimited on other plans.

### 2.2 Comparison and Analysis

#### Comparison Table: Serverless Platforms

| Feature               | AWS Lambda                                    | Google Cloud Functions               | Azure Functions                                   |
| --------------------- | --------------------------------------------- | ------------------------------------ | ------------------------------------------------- |
| **Max Execution Time**  | 15 minutes                                    | up to 60 minutes (2nd Gen)           | 10 min (Consumption), unlimited (other plans)     |
| **Key Differentiator**  | Mature, vast ecosystem                        | Simplicity, 2nd Gen built on Cloud Run | Durable Functions (stateful), hosting flexibility |
| **Cold Start Mitigation** | Provisioned Concurrency                       | Min instances (2nd Gen)              | Premium Plan                                      |

#### Analysis: Best Choice for a REST API Backend

For building a REST API backend, **AWS Lambda** is the recommended choice.

**Reasoning:**

1.  **Maturity & Ecosystem:** The combination of **Lambda and Amazon API Gateway** is the industry standard for serverless APIs. It is supported by a massive ecosystem of tools (Serverless Framework, AWS SAM), documentation, and community knowledge.
2.  **Community Support:** A vast community means that most development challenges have already been solved and documented, accelerating development.
3.  **Performance Features:** Mature features like `Provisioned Concurrency` provide a reliable solution for managing cold starts on latency-sensitive API endpoints.

#### Reflection: Serverless Advantages and Disadvantages

**Advantages:**

*   **No Server Management:** Developers focus on code, not infrastructure.
*   **Pay-per-use Model:** Highly cost-effective for variable or unpredictable workloads. You only pay when code runs.
*   **Automatic Scaling:** The platform scales seamlessly from zero to thousands of concurrent requests.
*   **Faster Time-to-Market:** Reduced operational overhead allows for faster development cycles.

**Disadvantages:**

*   **Cold Starts:** The first request after a period of inactivity can have higher latency.
*   **Platform Limitations:** Services have constraints on execution time, memory, and deployment package size.
*   **Vendor Lock-in:** Code becomes tightly coupled to the cloud provider's ecosystem (triggers, IAM, SDKs), making migration difficult.
*   **Debugging & Monitoring Complexity:** Tracing requests across a distributed system of functions can be more challenging than in a monolith.

---

### Sources

*   [AWS Documentation](https://docs.aws.amazon.com/)
*   [Google Cloud Documentation](https://cloud.google.com/docs)
*   [Microsoft Azure Documentation](https://docs.microsoft.com/en-us/azure/)