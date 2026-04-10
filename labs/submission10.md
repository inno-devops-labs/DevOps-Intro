# Lab 10 — Cloud Computing Fundamentals

**Student:** Kamilya Shakirova  
**Date:** 10-04-2026  

---

## Task 1 — Artifact Registries Research

- [x] Service name for each cloud provider  
- [x] Key features of each artifact registry  
- [x] Supported artifact types  
- [x] Integration capabilities  
- [x] Comparison table highlighting similarities and differences  
- [x] Analysis: Which registry service would you choose for a multi-cloud strategy and why?

### 1.1 Research Artifact Registries

Okay so I went through the docs for all three clouds and honestly it's a bit confusing at first because they all have different names and sometimes multiple services for basically the same thing. Here's what I found:

#### AWS: Amazon Elastic Container Registry (ECR) & AWS CodeArtifact

So AWS actually splits this into two separate services which is kind of annoying but whatever.

**ECR** is for Docker containers and OCI stuff. It's pretty straightforward — you push your images there and then ECS or EKS can pull them. The cool thing is it has vulnerability scanning built in now, and you can set up lifecycle rules so old images get deleted automatically instead of just sitting there costing money.

**CodeArtifact** is their package registry thing. It works with npm, PyPI, Maven, NuGet, etc. Basically if you're doing Node or Python development you can point your package manager at CodeArtifact and it'll cache everything from the public registries so your builds don't break if npm goes down again (which happens way too often tbh).

The integration with their CI/CD stuff is good obviously — CodeBuild and CodePipeline just work with both. IAM permissions are granular but kind of a pain to set up correctly.

#### GCP: Artifact Registry

Google's approach makes way more sense to me — it's just one service called Artifact Registry that handles both container images AND language packages. Like why wouldn't you do it that way? It supports Docker, Maven, npm, Python, Apt (which is weird but okay), Yum, Go modules, and even Helm charts.

The virtual repository thing is actually really useful — you can set it up so when someone does `npm install` it checks your private repo first, then falls back to the public npm registry, and caches everything so you're not hitting the public internet every time. Saves bandwidth and makes builds faster.

It also has container scanning which I guess is table stakes now. IAM works pretty much like AWS.

#### Azure: Azure Container Registry (ACR) & Azure Artifacts

Azure also splits things up. ACR for containers, Azure Artifacts for packages. ACR has some nice features like geo-replication if you pay for Premium tier, and the Defender for Cloud integration for security scanning. Azure Artifacts is really tightly integrated with Azure DevOps (obviously) — if you're already using Azure Boards and Pipelines it's super seamless.

One thing I noticed is that ACR supports OCI artifacts which means you can store Helm charts and other stuff there too, so it's not just Docker images anymore.

### 1.2 Comparison Table

| Feature | AWS (ECR + CodeArtifact) | GCP (Artifact Registry) | Azure (ACR + Artifacts) |
|---------|--------------------------|-------------------------|--------------------------|
| **Unified or split?** | Two separate services | Single service for everything | Two separate services |
| **Container images** | Yes (ECR) | Yes | Yes (ACR) |
| **Package managers** | npm, PyPI, Maven, NuGet, Swift | Maven, npm, Python, Apt, Yum, Go | NuGet, npm, Maven, Python |
| **Helm charts** | Via OCI in ECR | Native support | Via OCI in ACR |
| **Vulnerability scanning** | Inspector (separate-ish) | Built-in Container Scanning | Defender for Cloud |
| **Geo-replication** | Manual cross-region | Multi-regional repos | Premium tier only |
| **Pricing** | Pay for storage + data out | Pay for storage + egress | Similar tiered model |
| **CI/CD integration** | Native AWS tools | Cloud Build, Cloud Deploy | Azure DevOps native |

### 1.3 Which registry service would you choose for a multi-cloud strategy and why?

Honestly if I was building something that needed to work across multiple clouds, I'd probably go with **GCP Artifact Registry**. 

The main reason is that it's one service that does everything. If I have teams deploying to AWS and Azure and maybe some on-prem Kubernetes clusters, I don't want to maintain three different registry setups with different authentication methods and different UIs. Artifact Registry just works — it's a standard OCI registry endpoint plus standard package manager endpoints. Anyone can pull from it regardless of where they're running.

The remote repository proxying thing is also huge. In a multi-cloud setup you're probably pulling dependencies from all over the place, and having a single cache that works across clouds cuts down on egress costs and improves reliability.

The only downside is egress costs from GCP to other clouds, but you'd have that problem no matter which provider you pick as the central registry. At least with Artifact Registry you can pick multi-region locations to minimize latency.

I guess if my company was already all-in on Azure DevOps I might just use ACR and deal with the split, but for a clean-slate design GCP seems like the least messy option.

---

## Task 2 — Serverless Computing Platform Research

- [x] Service name(s) for each cloud provider  
- [x] Key features and capabilities  
- [x] Supported runtimes and languages  
- [x] Pricing comparison  
- [x] Performance characteristics  
- [x] Comparison table highlighting similarities and differences  
- [x] Analysis: Which serverless platform would you choose for a REST API backend and why?  
- [x] Reflection: What are the main advantages and disadvantages of serverless computing?

### 2.1 Research Serverless Computing Platforms

Serverless is one of those terms that everyone uses differently, but basically it means "I don't want to think about servers." Here's what each cloud has:

#### AWS: AWS Lambda

Lambda is like the OG serverless service. You write a function, upload it, and it runs when something triggers it — could be an HTTP request through API Gateway, a file uploaded to S3, a message in SQS, whatever.

You can use Node, Python, Java, .NET, Go, Ruby, or bring your own runtime. Recently they added container support which is huge because you're not stuck with their built-in runtimes anymore.

The cold start problem is real though. If your function hasn't been called in a while, it takes time to spin up a new instance. For Node or Python it's not terrible (under 100ms maybe), but for Java it can be seconds which is awful for a user-facing API. You can pay for Provisioned Concurrency to keep functions warm, but that kind of defeats the "pay only for what you use" thing.

Max timeout is 15 minutes. Billing is per millisecond which is nice and granular.

#### GCP: Cloud Functions & Cloud Run

Google has two serverless compute options. Cloud Functions is the direct Lambda competitor — it runs code in response to events. But honestly Cloud Run is more interesting for APIs.

Cloud Run lets you deploy any container and it'll scale it to zero when not in use, just like serverless functions, but you get a full HTTP server. You can use whatever language or framework you want as long as it runs in a container. It handles concurrency properly — one container instance can handle up to 1000 simultaneous requests, unlike Lambda where each instance handles one request at a time.

Cold starts are still a thing but you can set a minimum number of instances to stay warm. Timeout is 60 minutes for HTTP services which is way more generous than Lambda.

Pricing is based on vCPU and memory per second with a free tier that's actually pretty generous (2 million requests/month).

#### Azure: Azure Functions & Container Apps

Azure has basically copied the same pattern. Azure Functions is the event-driven thing with a bunch of triggers and bindings. They have different hosting plans — Consumption (true pay-per-use), Premium (warm instances, better cold start, VNet integration), and Dedicated (just regular App Service).

Container Apps is their Cloud Run equivalent — serverless containers with scale-to-zero, Dapr integration for microservices stuff, and KEDA-based autoscaling.

One thing I noticed is that Azure Functions Consumption plan has a hard timeout of like 230 seconds unless you go to Premium, which is really short compared to GCP's 60 minutes.

### 2.2 Comparison Table

| Feature | AWS Lambda | GCP Cloud Functions / Cloud Run | Azure Functions / Container Apps |
|---------|------------|--------------------------------|--------------------------------|
| **Execution model** | Event-driven + API Gateway | HTTP-native (Cloud Run) + event-driven (Functions) | HTTP + event-driven |
| **Max timeout** | 15 min | 60 min (HTTP), 24h (jobs) | 230s (Consumption), unlimited (Premium) |
| **Concurrency** | One request per instance | Configurable up to 1000 per instance | Configurable per instance |
| **Cold start mitigation** | Provisioned Concurrency (paid) | Min instances (paid) | Premium plan / Always Ready (paid) |
| **Language support** | Native runtimes + custom + containers | Predefined runtimes or any container | Rich native + any container |
| **Pricing granularity** | 1ms | 100ms | 1ms |
| **Free tier** | 1M requests + 400k GB-s | 2M requests + credits | 1M executions |

### 2.3 Which serverless platform would you choose for a REST API backend and why?

For a REST API backend I'd probably pick **Cloud Run** on GCP.

The biggest reason is the concurrency model. When you're building an API, you're going to have multiple requests coming in at the same time. With Lambda, each request spins up its own function instance (or reuses a warm one if available), but they're still isolated. Cloud Run lets a single container handle many requests concurrently, which is just more efficient and reduces cold start pain because the container is already warm handling other traffic.

Also the 60-minute timeout is way more realistic for API endpoints. I've had cases where a file upload or a report generation takes more than 30 seconds, and hitting Lambda's 15-minute limit isn't the issue but it's nice to know you have headroom. Plus you don't have to rearchitect everything into async jobs just because a process takes 16 minutes.

The fact that you deploy a standard container means I can run the exact same thing locally with Docker, test it properly, and then push it to prod. No "it works on my machine but not in Lambda" nonsense.

If I was already deep in AWS with DynamoDB and SQS everywhere, I'd probably just stick with Lambda and deal with API Gateway. But for a new project or if I had a choice, Cloud Run feels more modern and less restrictive.

### 2.4 Reflection: What are the main advantages and disadvantages of serverless computing?

**Advantages:**

- **No servers to manage** — this is the obvious one. I don't have to patch operating systems or worry about running out of disk space on some VM.
- **Scales automatically** — if my API suddenly gets a ton of traffic, it just scales up. When it's quiet at 3am, it scales to zero and costs nothing.
- **Pay for actual usage** — I'm not paying for idle capacity. For a side project or a startup this is huge.
- **Faster development** — I can just write a function and deploy it without setting up CI/CD pipelines for infrastructure.

**Disadvantages:**

- **Cold starts** — if a function hasn't been used in a while, the first request is slow. For user-facing stuff this can be really noticeable. You can pay to keep things warm but then you lose some of the cost benefit.
- **Vendor lock-in** — if I write a bunch of Lambda functions that use S3 triggers and DynamoDB streams, moving to another cloud is going to be painful. Container-based serverless helps with this but you're still tied to the platform's APIs for stuff like authentication and logging.
- **Time and memory limits** — you can't run a machine learning training job or a long video encoding task in a Lambda function. There are hard limits that you have to design around.
- **Debugging is harder** — when something breaks in production, you can't just SSH into the server and look at logs. You have to rely on whatever logging and tracing the cloud provider gives you, and correlating events across dozens of function invocations is a pain.
- **Cost at scale** — this is the one that surprised me. For low to medium traffic, serverless is cheap. But if you have consistently high traffic, running a few reserved instances or a Kubernetes cluster can actually be cheaper. There's a crossover point where serverless stops being cost-effective.
