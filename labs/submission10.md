# Task 1

In this task, I researched artifact registry services from AWS, Google Cloud, and Azure. These services are used to store and manage container images and other build artifacts. They are important in DevOps because applications often need a secure and reliable place where images and packages are stored before deployment.

## AWS - Amazon Elastic Container Registry (ECR)

For AWS, the main artifact registry service is Amazon Elastic Container Registry, or Amazon ECR. I found that ECR is mainly focused on container images and OCI artifacts. It supports Docker images, OCI images, and Helm charts stored as OCI artifacts. It also has useful security features such as vulnerability scanning and access control through AWS IAM. Another important feature is replication across regions and accounts. ECR integrates very well with other AWS services such as ECS, EKS, and CI/CD pipelines. In terms of pricing, it is mostly based on how much data is stored and transferred.

## GCP - Artifact Registry

For Google Cloud, the main service is Artifact Registry. Out of the three providers, this one seems the most universal to me. It supports not only container images but also many package formats such as npm, Maven, Python, APT, and YUM. This makes it useful not only for containers but also for general dependency management. It includes IAM-based access control, cleanup policies, and vulnerability scanning. It also integrates well with Cloud Build, GKE, and Cloud Run. Its pricing is also based mainly on storage and network usage.

## Azure - Azure Container Registry (ACR)

For Azure, the main service is Azure Container Registry, or ACR. Like Amazon ECR, it is strongly focused on container and OCI artifacts. It supports Docker images, OCI artifacts, and Helm charts as OCI artifacts. ACR includes access control, automation features through ACR Tasks, and geo-replication in the Premium tier. It integrates well with Azure services such as AKS and App Service. Its pricing is based on service tiers such as Basic, Standard, and Premium.

## Comparison

If I compare these three services, I can say that all of them support container image storage, security controls, and integration with the cloud provider's ecosystem. The main difference is that Google Artifact Registry supports a wider range of package types, while AWS ECR and Azure ACR are more container-centered.

Here is my comparison table:


| Provider | Service                  | Main Support                             | Key Strengths                                 | Pricing Basics       |
| -------- | ------------------------ | ---------------------------------------- | --------------------------------------------- | -------------------- |
| AWS      | Amazon ECR               | Docker, OCI images, Helm OCI             | Strong AWS integration, replication, scanning | Storage and transfer |
| GCP      | Artifact Registry        | Containers, npm, Maven, Python, APT, YUM | Broad package support, cleanup policies       | Storage and transfer |
| Azure    | Azure Container Registry | Docker, OCI images, Helm OCI             | Geo-replication, ACR Tasks, Azure integration | Tier-based pricing   |


## Analysis

If I had to choose one registry for a multi-cloud strategy, I would choose Google Artifact Registry. I think it is the best option because it supports the widest range of artifact types. In a multi-cloud environment, teams often work not only with containers but also with language packages and dependencies. Because of that, Artifact Registry looks more flexible to me. At the same time, if a company is deeply tied to AWS or Azure, then ECR or ACR may be a better practical choice because they are more deeply integrated into their own ecosystems.

# Task 2

In this task, I researched serverless computing platforms from AWS, Google Cloud, and Azure. Serverless computing allows developers to run code without managing servers directly. This is useful because it reduces operational work and allows applications to scale automatically.

## AWS - AWS Lambda

For AWS, the main serverless service is AWS Lambda. Lambda is event-driven and can run code in response to many triggers, such as HTTP requests, file uploads, queue messages, or database events. It supports multiple programming languages and also allows custom runtimes. Lambda has a maximum execution time of 15 minutes. One issue with Lambda is cold starts, but AWS provides features such as Provisioned Concurrency and SnapStart to reduce startup delay. Pricing is based mainly on the number of requests and execution time.

## GCP - Cloud Run

For Google Cloud, I chose Cloud Run as the main serverless platform. I think Cloud Run is especially strong because it is container-based. This means developers can package their application as a container and deploy it directly. It supports HTTP services and event-driven workloads. Cloud Run allows more flexibility than a classic function-only platform because it can run almost any containerized application. It supports request timeouts up to 60 minutes. Cold starts still exist, but Google allows minimum instances to reduce them. Pricing is based on requests, CPU, and memory usage.

## Azure - Azure Functions

For Azure, the main service is Azure Functions. It supports several languages, including C#, Python, Java, JavaScript, and others. Like AWS Lambda, it is event-driven and can also handle HTTP requests, timers, and queue-based triggers. Azure Functions has different hosting plans, so some limits depend on the selected plan. One important point is that HTTP-triggered functions have a practical response limit because of Azure Load Balancer timeout behavior. Cold starts may also happen, but Azure has always-ready or prewarmed instances in some plans. Pricing depends on the hosting model, but in general it follows pay-per-use logic.

## Comparison

Here is my comparison table for serverless services:


| Provider | Service         | Execution Model                           | Max Duration                 | Cold Start Solutions               | Pricing Basics                 |
| -------- | --------------- | ----------------------------------------- | ---------------------------- | ---------------------------------- | ------------------------------ |
| AWS      | AWS Lambda      | Event-driven, HTTP through integrations   | 15 minutes                   | Provisioned Concurrency, SnapStart | Per request and execution time |
| GCP      | Cloud Run       | HTTP and event-driven containers          | Up to 60 minutes per request | Minimum instances                  | Per request, CPU, memory       |
| Azure    | Azure Functions | Event-driven, HTTP, timer, queue triggers | Depends on plan              | Always-ready / prewarmed instances | Pay per use or plan-based      |


## Analysis

If I had to choose a serverless platform for a REST API backend, I would choose Google Cloud Run. The main reason is that it feels more flexible to me than a traditional functions-only platform. Since Cloud Run works with containers, I can package the whole API exactly how I want, with any framework and dependencies. I also like that it is HTTP-oriented by design. For a modern REST API, this seems very convenient.

AWS Lambda is also a very strong choice, especially for APIs that are deeply connected with AWS services. However, I think Lambda is a bit more restrictive because it is more function-oriented. Azure Functions is also useful, especially in Microsoft environments, but I think Cloud Run feels simpler and more flexible for a normal API backend.

## Reflection

In my opinion, the main advantages of serverless computing are lower operational overhead, automatic scaling, and pay-per-use pricing. It is also good for fast development because the cloud provider handles much of the infrastructure.

At the same time, serverless also has disadvantages. Cold starts can increase latency. Execution limits can be a problem for long-running tasks. It may also create vendor lock-in, because each provider has its own triggers, integrations, and service model. Finally, debugging and monitoring can become harder in distributed event-driven systems.

Overall, this lab helped me understand that AWS, GCP, and Azure all provide strong cloud services, but they have different strengths. For artifact registries, I would prefer Google Artifact Registry in a multi-cloud environment because it supports more package types. For serverless REST APIs, I would choose Google Cloud Run because it gives me the flexibility of containers together with the simplicity of serverless deployment.

## References

**Task 1 — artifact registries**

- [Amazon ECR — What is Amazon ECR?](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [Google Artifact Registry documentation](https://cloud.google.com/artifact-registry/docs)
- [Azure Container Registry documentation](https://learn.microsoft.com/azure/container-registry/)

**Task 2 — serverless compute**

- [AWS Lambda — What is AWS Lambda?](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Google Cloud Run documentation](https://cloud.google.com/run/docs)
- [Google Cloud Functions documentation](https://cloud.google.com/functions/docs) (GCP’s function-style option alongside Cloud Run)
- [Azure Functions documentation](https://learn.microsoft.com/azure/azure-functions/)

