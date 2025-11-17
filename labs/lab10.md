# Lab 10 — Cloud Computing Fundamentals

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-Cloud%20Computing-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Research and compare artifact registries and serverless computing platforms across major cloud providers (AWS, GCP, Azure).  
> **Deliverable:** A PR from `feature/lab10` to the course repo with `labs/submission10.md` containing comparative analysis of cloud services. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Researching **artifact registries** across AWS, GCP, and Azure.
- Comparing **serverless computing platforms** on major cloud providers.
- Analyzing key features, pricing models, and use cases for cloud services.
- Documenting findings in a structured, comparative format.

These skills are essential for making informed decisions about cloud infrastructure and selecting appropriate services for DevOps workflows.

---

## Tasks

### Task 1 — Artifact Registries Research (5 pts)

**Objective:** Identify and document the most popular artifact registries in AWS, GCP, and Azure.

**Why This Matters:** Artifact registries are critical for storing, managing, and distributing container images, packages, and build artifacts in modern DevOps pipelines. Understanding different registry options helps you choose the right solution for your infrastructure.

#### 1.1: Research Artifact Registries

1. **Explore Cloud Provider Documentation:**

   Research the official documentation and services for:
   - **AWS:** Identify AWS's primary artifact registry service
   - **GCP:** Identify GCP's primary artifact registry service
   - **Azure:** Identify Azure's primary artifact registry service

   <details>
   <summary>🔍 What to research</summary>

   For each artifact registry service, investigate:
   - Official service name
   - What types of artifacts it supports (container images, npm packages, Maven, etc.)
   - Key features (security scanning, geo-replication, access control, etc.)
   - Integration with other cloud services
   - Pricing model basics
   - Common use cases

   </details>

#### 1.2: Document Your Findings

In `labs/submission10.md`, document:
- Service name for each cloud provider
- Key features of each artifact registry
- Supported artifact types
- Integration capabilities
- Comparison table highlighting similarities and differences
- Analysis: Which registry service would you choose for a multi-cloud strategy and why?

---

### Task 2 — Serverless Computing Platform Research (5 pts)

**Objective:** Identify and document the best serverless computing platforms in AWS, GCP, and Azure.

**Why This Matters:** Serverless computing enables developers to run code without managing servers, reducing operational overhead and enabling auto-scaling. Understanding serverless options is crucial for modern application architecture.

#### 2.1: Research Serverless Computing Platforms

1. **Explore Serverless Offerings:**

   Research serverless computing services for:
   - **AWS:** Identify AWS's primary serverless compute service(s)
   - **GCP:** Identify GCP's primary serverless compute service(s)
   - **Azure:** Identify Azure's primary serverless compute service(s)

   <details>
   <summary>🔍 What to research</summary>

   For each serverless platform, investigate:
   - Official service name(s)
   - Supported programming languages/runtimes
   - Execution models (event-driven, HTTP-triggered, etc.)
   - Cold start performance characteristics
   - Integration with other cloud services
   - Pricing model (per invocation, per execution time, etc.)
   - Maximum execution duration limits
   - Common use cases and architectures

   </details>

#### 2.2: Document Your Findings

In `labs/submission10.md`, document:
- Service name(s) for each cloud provider
- Key features and capabilities
- Supported runtimes and languages
- Pricing comparison
- Performance characteristics
- Comparison table highlighting similarities and differences
- Analysis: Which serverless platform would you choose for a REST API backend and why?
- Reflection: What are the main advantages and disadvantages of serverless computing?

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab10
   # create labs/submission10.md with your findings
   git add labs/submission10.md
   git commit -m "docs: add lab10 submission"
   git push -u origin feature/lab10
   ```

2. Open a PR from your fork's `feature/lab10` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Artifact Registries Research
   - [x] Task 2 — Serverless Computing Platform Research
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab10` exists with commits for each task.
- ✅ File `labs/submission10.md` contains comprehensive research and analysis for Tasks 1-2.
- ✅ Comparison tables included for both artifact registries and serverless platforms.
- ✅ Analysis demonstrates understanding of cloud service differences.
- ✅ PR from `feature/lab10` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                       | Points |
| ----------------------------------------------- | -----: |
| Task 1 — Artifact Registries Research           |  **5** |
| Task 2 — Serverless Computing Platform Research |  **5** |
| **Total**                                       | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission10.md`.
- Include comparison tables for easy reference.
- Cite official documentation sources.
- Provide thoughtful analysis beyond just listing features.
- Focus on understanding trade-offs between different cloud providers.

<details>
<summary>📚 Helpful Resources</summary>

**AWS Documentation:**
- [AWS Documentation Portal](https://docs.aws.amazon.com/)
- [AWS Services Overview](https://aws.amazon.com/products/)

**GCP Documentation:**
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [GCP Products and Services](https://cloud.google.com/products)

**Azure Documentation:**
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Services Directory](https://azure.microsoft.com/en-us/services/)

</details>

<details>
<summary>💡 Research Tips</summary>

1. Start with official cloud provider documentation for accurate information.
2. Look for comparison articles and whitepapers from reputable sources.
3. Check pricing pages to understand cost models.
4. Review case studies to understand real-world use cases.
5. Consider factors like vendor lock-in, migration complexity, and ecosystem integration.
6. Use comparison tables to organize your findings clearly.

</details>

<details>
<summary>🎯 Key Comparison Factors</summary>

**For Artifact Registries:**
- Supported artifact formats
- Security features (vulnerability scanning, access control)
- Geographic distribution and replication
- Integration with CI/CD tools
- Storage limits and pricing
- Performance and reliability

**For Serverless Platforms:**
- Language/runtime support
- Cold start latency
- Execution duration limits
- Concurrency and scaling
- Event sources and triggers
- Pricing model (pay-per-execution)
- Observability and monitoring

</details>