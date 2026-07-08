<h1>Task 1</h1>

<b>add yml in .github/workflows/release.yml</b>

```git tag -a -s v0.1.0 -m "Lab 10 release"```

```git push origin v0.1.0```

Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 381 bytes | 381.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/sovva6-14/DevOps-Intro.git
 * [new tag]         v0.1.0 -> v0.1.0

<h1>Questions: <h1>

a) OIDC vs GITHUB_TOKEN - for pushing to ghcr.io from the same repo, GITHUB_TOKEN with packages: write is enough. When would you reach for OIDC instead, and what does it give you that GITHUB_TOKEN doesn't?

<b>You would use OIDC (OpenID Connect) instead of GITHUB_TOKEN when:</b>

* <b>Pushing to external registries:</b> OIDC allows GitHub Actions to authenticate to AWS ECR, Google Artifact Registry, or Azure Container Registry without storing long-lived credentials as secrets
* <b>Cross-repository access:</b> If you need to push images from repo A to a container registry owned by repo B, OIDC with workload identity federation provides fine-grained, short-lived access
* <b>Audit trail:</b> OIDC provides a verifiable token that links the authentication request to the specific workflow run and GitHub repository, improving auditability

<b>OIDC benefits over GITHUB_TOKEN:</b>

* <b>No secret rotation:</b> OIDC issues short-lived tokens (up to 5 minutes) that are automatically rotated, eliminating secret management overhead
* <b>Federated identity:</b> Works across cloud providers without sharing credentials
* <b>Fine-grained permissions:</b> You can scope OIDC to specific workload identities, not just the entire repository
* <b>Security:</b> Reduces the risk of leaked credentials since tokens are ephemeral and cannot be used outside the workflow context

b) :latest tag vs :v0.1.0 immutable tag - Lab 6 covered why :latest is mutable. So why do you still ship a :latest tag alongside the immutable one in production releases?

You ship :latest alongside the immutable version tag because:

* <b>Development convenience:</b> :latest provides a stable, well-known reference for developers and staging environments who want to always use the newest version without updating manifests.
* <b> Rollback simplicity:</b> In case of deployment issues, you can quickly roll back by pointing :latest to a previous commit without changing CI configuration.
* <b>Demo/quick-start purposes:</b> New users or evaluators can simply docker pull <image>:latest to get the most recent release without knowing the exact version number.
* <b>Documentation simplicity:</b> Tutorials and examples can reference :latest instead of updating documentation for every release.

The immutable tag (:v0.1.0) ensures:

* Exact traceability for production deployments
* Reproducible builds
* Ability to run multiple versions simultaneously

c) packages: write scope only - what's the principle, and what concrete attack does the narrow scope prevent vs write: all?

The principle is least privilege - granting only the minimum permissions necessary to perform the task

Concrete attack prevented: If an attacker compromises the CI workflow (e.g., through a malicious action or dependency), a packages: write scope limits the damage to:

* Pushing/pulling container images to ghcr.io
* Modifying package metadata

With write: all, the attacker would gain:

* Write access to repository code (push commits, delete branches)
* Access to all repository secrets (including potential AWS/Azure keys)
* Ability to create malicious releases or tags
* Write access to GitHub Pages, issues, project boards, and all other repository resources

The narrow scope prevents privilege escalation: even if an attacker can push a malicious image, they cannot modify the repository source code, steal deployment credentials, or compromise other integrated services

<h1>Task 2</h1>

I ran into a problem after registering on the site. I received a confirmation email, but when I clicked the link to activate my account, I got an "Access denied" error (even though I was using a VPN). In https://cdn-uploads.huggingface.co access denied (lol)

AccessDeniedAccess Denied
This XML file does not appear to have any style information associated with it. The document tree is shown below.
<Error>
<Code>AccessDenied</Code>
<Message>Access Denied</Message>
...
</Error>

<h1>Questions: <h1>

d) HF Spaces "sleep" vs Cloud Run "scale to zero" — same idea, different orders of magnitude. Why is HF's wake so much slower? What does the platform optimize for differently?

HF Spaces is optimized for developer convenience and cost, not performance:
* <b>Underlying infrastructure:</b> HF Spaces runs on shared, lower-performance compute (likely older CPUs with limited network bandwidth) compared to Cloud Run's SSD-backed, high-speed infrastructure
* <b>Container cold start:</b> HF pulls the image from scratch on each cold start (no image pre-warming), while Cloud Run maintains a warm pool of pre-loaded container images
* <b>Resource contention:</b> HF Spaces are multi-tenant with less aggressive resource isolation, leading to slower startup when resources are contended
* <b>Different trade-off:</b> HF prioritizes a free, accessible platform for ML demos over fast cold starts. Cloud Run optimizes for enterprise workloads where sub-second scaling is business-critical

e) Why does the Space need app_port: 8080? What's HF's default and why do they default to that?

* <b>HF Default:</b> 7860 (used by Gradio and Streamlit apps)
* <b>Why 7860:</b> This is the default port for Gradio interfaces, which are the most common application type on HF Spaces. Many ML demos use Gradio, so HF optimized for this default
* <b>Why we need to change it:</b> QuickNotes is a Go REST API that listens on port 8080 (a common backend API port). If we don't set app_port: 8080, HF would try to connect to port 7860, find nothing listening, and mark the Space as "failed"

f) You pulled the image from ghcr.io into the Space. What's the trade-off vs building the Dockerfile inside the Space? (Hint: caching, reproducibility, debug-ability)

See the table in section 2.1 for details. The key trade-offs are:

* <b>Caching: </b>Pulling uses HF's layer cache (fast), while building inside the Space must download dependencies on every deploy (slow).
* <b>Reproducibility:</b> Pulling ensures the exact same binary runs everywhere, while building inside the Space can produce different results due to timestamp changes or network variations.
* <b>Debug-ability:</b> Pulling allows local testing of the same image before pushing, while building inside the Space is a "black box" that's hard to debug when it fails.
