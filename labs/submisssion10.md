## Task 1

### AWS
Service name: AWS CodeArtifact

Supported package formats:  Cargo, generic, Maven, npm, NuGet, PyPI, Ruby, Swift, generic

Key features: high availability and durability, access control

Integration with: AWS Identity and Access Management, CloudTrail, AWS KMS

Pricing: Pay-as-you-go, separate bills for store/request/transfer

### GCP
Service name: Google artifact-registry

Supported package formats: Docker, Maven, npm, Python, Apt, Yum, Kubeflow, Go, Debian, RPM, generic

Key features: security, integration with Google's other services, remote and virtual artifact repositories, containers support

Integration with: Google Kubernetes Engine, Cloud Run, Compute Engine, App Engine, Google Cloud CI/CD

Pricing: Free plan available, Pay-as-you-go otherwise

### Azure

Service name: Azure Artifacts

Supported package formats: Maven, npm, NuGet, Python, Cargo, Dotnet, Gradle, generic

Key features: Integrated CI/CD, AI integration, availability during downtime

Integration with: Azure Pipelines, Copilot

Pricing: 30-day trial, Pay-as-you-go

| Capability                       | **AWS CodeArtifact**                                          | **GCP Artifact Registry**                                     | **Azure Artifacts**                                   |
| -------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| **Containers support**           | No                                                            | Yes (native)                                                  | No                                                    |
| **Public-registry upstreaming**  | Yes (npm, PyPI, Maven Central, NuGet)                         | Yes (via remote repos)                                        | Yes (npm, Maven, NuGet, PyPI)                         |
| **Repository types**             | Private + upstream, but no true “virtual repos”               | Local, remote, virtual (aggregate)                            | Feeds with upstream sources                           |
| **Storage model**                | Object-storage-backed, similar to S3                          | Region-scoped repositories                                    | Per-organization feed storage                         |
| **Pricing**          | Free 2 GB + request-based billing                             | Region-dependent rates; heavier focus on network egress costs | First 2 GB per org free; mostly storage-based billing |
| **Best suited for**              | Polyglot package repos inside AWS                             | Mixed containers + packages in one place                      | Teams using Azure DevOps                              |

For a multi-cloud strategy GCP would be the best service among those, since it is more portable and repositories are region-scoped

## Task 2

### AWS

Official services names: AWS Lambda

Supported programming languages/runtimes: Node.js, Python, Java, Dotnet, Go, Ruby, custom are supported

Execution models (event-driven, HTTP-triggered, etc.): event-driven, HTTP-triggered, scheduled

Cold start performance characteristics: avg 100-2000ms

Integration with other cloud services: basically all AWS ecosystem including S3

Pricing model (per invocation, per execution time, etc.): Free plan available, Pay-per-use

Maximum execution duration limits: up to 15min per instance

Common use cases and architectures: S3 uploads and processing, microservices, light compute

### GCP

Official service name: Google Cloud Run

Supported programming languages/runtimes: Node.js, Python, Go, Java, Dotnet, PHP, Ruby, generic

Execution models (event-driven, HTTP-triggered, etc.): HTTP-triggered

Cold start performance characteristics: avg 200-1500ms

Integration with other cloud services: GCP ecosystem

Pricing model (per invocation, per execution time, etc.): Free plan available, Pay-per-use

Maximum execution duration limits: Plan-dependent, up to 60min per instance

Common use cases and architectures: web backend, simple services

### Azure

Official service name: Azure Functions

Supported programming languages/runtimes: Dotnet, Node.js, Python, Java, generic

Execution models (event-driven, HTTP-triggered, etc.): HTTP-triggered, scheduled, event-driven

Cold start performance characteristics: avg 200-3000ms

Integration with other cloud services: Microsoft ecosystem

Pricing model (per invocation, per execution time, etc.): Pay-per-use, "free" trial

Maximum execution duration limits: shortest, 230 seconds

Common use cases and architectures: Dotnet projects, enterprise microservices

For a REST API backend I would use Google Cloud Run since it is concurrent and optimised for HTTP workloads (as per their documentation). Also idling is free.

Advantages: provisioning and handling by the service, high availability, integration with respective ecosystems
Disadvantages: cold starts, limited execution time