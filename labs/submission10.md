# Task 1


## Service name for each cloud provider
- **AWS:** **Amazon ECR**
- **GCP:** **Google Artifact Registry**
- **Azure:** **Azure Container Registry**

## Key features of each artifact registry

### Amazon ECR
- OCI and Docker support
- Public container image and artifact gallery
- AWS Marketplace
- Access control
- Encryption
- Image signing and trust verification
- Image vulnerability scanning

### Google Artifact Registry
- Unified artifact service (containers + packages)
- IAM controls, audit logging, CMEK support
- Container vulnerability scanning
- Remote and virtual repository modes

### Azure Container Registry (ACR)
- Managed private OCI registry
- Microsoft access control
- Geo-replication for global pull performance
- Image scanning options through Microsoft Defender
- Content trust/signing and artifact support (OCI-based)
- Tasks/automations for image build, patch, and maintenance
- Private networking

## Supported artifact types

- **Amazon ECR:** Docker/OCI container images, OCI artifacts (Helm charts, signatures etc.)
- **Google Artifact Registry:** Docker/OCI images and additional package formats (npm, Maven, PyPI, etc.)
- **Azure ACR:** Docker/OCI container images and OCI artifacts (including Helm via OCI workflow)


## Integration capabilities

- **Amazon ECR:** ECS, EKS, Lambda (container images), CodeBuild/CodePipeline, IAM, CloudTrail, CloudWatch
- **Google Artifact Registry:** GKE, Cloud Run, Cloud Build, IAM, Cloud Logging, Binary Authorization
- **Azure ACR:** AKS, Azure Container Apps, App Service (containers), Azure DevOps/GitHub Actions, Defender for Cloud, Azure Policy


## Comparison table highlighting similarities and differences

| | Amazon ECR | Google Artifact Registry | Azure ACR |
|---|---|---|---|
| Primary scope | Container/OCI registry | Unified artifacts (containers + packages) | Container/OCI registry |
| Container support | Yes (core) | Yes | Yes (core) |
| Non-container package support | Limited vs package-focused services | Yes | Mainly OCI-focused |
| Access control | AWS IAM + repo policies | Google IAM | Azure services |
| Geo replication | Yes | Regional/multi-regional design | Yes |
| Vulnerability scanning | Yes | Yes | Yes |
| Best fit | AWS-native container platforms | Mixed artifact needs in GCP | Azure-native container platforms |


## Analysis: Which registry service would you choose for a multi-cloud strategy and why?

I will choose **Google Artifact Registry** if one registry must handle both containers and language packages in one platform. Moreover, google almost always have good documentation for all their services. 

# Task 2

## Service names by cloud provider

- **AWS:** **AWS Lambda**
- **GCP:** **Cloud Functions (2nd gen)** and **Cloud Run** 
- **Azure:** **Azure Functions** 


## Key features and capabilities (summary)

- All three provide auto-scaling, event triggers, pay-per-use pricing, IAM/RBAC security, and monitoring integration.
- AWS Lambda has the deepest native event-source ecosystem in AWS.
- GCP Cloud Run offers strongest container portability for serverless workloads.
- Azure Functions integrates tightly with Microsoft enterprise stack and Azure integration services.

## Pricing comparison

| Platform | Core billing model |
|---|---|
| AWS Lambda | Requests + GB-seconds |
| GCP Cloud Functions / Cloud Run | Requests + CPU/memory time | 
| Azure Functions | Executions + execution time (Consumption), or instance-based (Premium/Dedicated) | 

## Performance characteristics 

- **Cold starts:** possible on all platforms when scaled to zero
- **Mitigations:** pre-warmed/provisioned capacity (Lambda Provisioned Concurrency, Cloud Run min instances, Azure Premium plan)
- **Latency stability:** generally best when minimum warm capacity is configured

## Similarities and differences table

| Dimension | AWS Lambda | GCP Cloud Functions / Cloud Run | Azure Functions |
|---|---|---|---|
| Primary model | FaaS | FaaS + serverless containers | FaaS |
| HTTP support | Yes (API Gateway/URLs) | Yes (native) | Yes |
| Event-driven | Strong | Strong | Strong |
| Max single execution | 15 min | up to 60 min (common) | Plan-dependent |
| Container-first option | Yes (container image packaging) | **Yes (Cloud Run native)** | Limited compared to Cloud Run model |
| Cold start controls | Provisioned Concurrency | Min instances | Premium plan always-ready |

### Analysis: best platform for a REST API backend

For a new REST API backend, **GCP Cloud Run** is a strong default choice because it supports any language via containers, has simple HTTP deployment, scales to zero, and is portable across environments.

If already deeply invested in AWS services/events, **AWS Lambda + API Gateway** is often the most integrated option

### Reflection: advantages and disadvantages of serverless computing

**Advantages**
- No server management.
- Automatic scaling.
- Pay for usage.
- Faster delivery and simpler ops for many workloads.


**Disadvantages**
- Cold starts can affect latency.
- Harder local debugging and observability complexity in distributed flows.
- Vendor lock-in risk via provider-specific triggers/services.
- Execution time/runtime constraints for long-running workloads.


