# Lab 10 Submission — Cloud Computing


## Task 1 — CI-Automated Push to ghcr.io (6 pts)

### Workflow File
- Path: `.github/workflows/release.yml`
- [Link to file](https://github.com/03sano30/DevOps-Intro/blob/feature/lab10/.github/workflows/release.yml)

### Registry URLs
```
ghcr.io/03sano30/devops-intro/quicknotes:latest
ghcr.io/03sano30/devops-intro/quicknotes:v0.1.1
```

### Successful Pull Evidence
```powershell
PS C:\Users\User\Desktop\Инно\3 триместр\девопс\DevOps-Intro> docker images | findstr quicknotes

WARNING: This output is designed for human readability. For machine-readable output, please use --format.
devops-intro-quicknotes:latest                    920fb4ee1493       41.1MB         13.7MB        
ghcr.io/03sano30/devops-intro/quicknotes:latest   167d249cf284       22.8MB         5.71MB        
ghcr.io/03sano30/devops-intro/quicknotes:v0.1.1   167d249cf284       22.8MB         5.71MB        
quicknotes:lab6                                   fcdb60185081       22.8MB         5.71MB   U    
```

**Pull Command Output:**
```powershell
PS C:\Users\User\Desktop\Инно\3 триместр\девопс\DevOps-Intro> docker pull ghcr.io/03sano30/devops-intro/quicknotes:latest
latest: Pulling from 03sano30/devops-intro/quicknotes
62b9eda734ac: Pull complete 
cbc07e3aa8b7: Pull complete 
6341d8388da1: Pull complete 
43a0845913c7: Pull complete 
bbc4fefec52a: Pull complete 
Digest: sha256:167d249cf284b07eecf809e8cd6a211fc605cec2671a16796c7b998bed5a8d78
Status: Downloaded newer image for ghcr.io/03sano30/devops-intro/quicknotes:latest
```

### CI Run URL
https://github.com/03sano30/DevOps-Intro/actions/runs/28743713109

### Screenshots
![GitHub Actions Workflow](image.png)
![GitHub Package Public](image-1.png)

### Design Questions

**a) OIDC vs GITHUB_TOKEN**

OIDC (OpenID Connect) is used for authentication with external cloud services (AWS, GCP, Azure). It provides short-lived tokens with fine-grained issuance conditions (e.g., only for specific branches or environments).

`GITHUB_TOKEN` is sufficient for operations within GitHub and provides basic permissions for repository operations.

OIDC is more secure for external services because:
- Tokens live only during workflow execution
- No long-lived secrets need to be stored
- Allows fine-grained access control

**b) :latest vs immutable tag**

`:latest` is needed for:
- Development convenience (always get the latest version)
- CI/CD pipelines for dev/staging environments
- Quick deployment without specifying a version

Immutable tag (`v0.1.1`) is needed for:
- Stability and reproducibility in production
- Ability to precisely rollback to a specific version
- Deterministic deployments

Both tags are necessary: `:latest` for development, versioned tag for production.

**c) packages: write scope**

The principle of Least Privilege — give only the permissions absolutely necessary to perform the task.

The narrow `packages: write` scope prevents:
- Modification of other packages in the repository
- Deletion of other users' packages
- Changing repository settings
- Access to secrets

This significantly limits potential damage if the workflow or token is compromised.

---

## Task 2 — Hugging Face Spaces (4 pts)

### Space URL
- Space page: https://huggingface.co/03sano30/spaces

### Health Check
```powershell
PS C:\Users\User\Desktop\Инно\3 триместр\девопс\DevOps-Intro\quicknotes> curl https://03sano30-quicknotes.hf.space/health

StatusCode        : 200
StatusDescription : OK
Content           : {"notes":4,"status":"ok"}
RawContentLength  : 26
```

### Push to Space
```powershell
PS C:\Users\User\Desktop\Инно\3 триместр\девопс\DevOps-Intro\quicknotes> git push origin main
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 883 bytes | 441.00 KiB/s, done.
Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
To https://huggingface.co/spaces/03sano30/quicknotes
   5058378..c4d1f09  main -> main
```

### Space Files
- [Dockerfile](https://huggingface.co/spaces/03sano30/quicknotes/blob/main/Dockerfile)
- [README.md](https://huggingface.co/spaces/03sano30/quicknotes/blob/main/README.md)

**Dockerfile content:**
```dockerfile
FROM ghcr.io/03sano30/devops-intro/quicknotes:latest
EXPOSE 8080
CMD ["./quicknotes"]
```

**README.md content:**
```markdown
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
---

# QuickNotes

A simple note-taking application deployed on Hugging Face Spaces.

## API Endpoints
- GET /health - Health check
- POST /notes - Create a note
- GET /notes - List all notes
- GET /notes/{id} - Get a note
- PUT /notes/{id} - Update a note
- DELETE /notes/{id} - Delete a note
```

### Latency Measurements

**Warm Latency (5 consecutive requests):**
```
Request 1 : 3.634 s   ← Space was waking up (was asleep)
Request 2 : 0.505 s
Request 3 : 0.508 s
Request 4 : 0.453 s
Request 5 : 0.677 s

p50 (median): 0.508 s
```

**Cold Latency (3 measurements after 35+ min idle):**
```
1. 1.346 s   (cold start - Space was waking up)
2. 1.653 s   (cold start - Space was waking up)
3. 0.954 s   (cold start - Space was waking up)
```

> **Note:** All three measurements were performed after waiting 35+ minutes, so all show cold start. The variation in time is explained by different cache states and HF infrastructure load at the time of the request.

**Average cold start time:** `~1.318 s`

### Screenshots
![HF Space Created & Running](image-2.png)
![HF Build Logs](image-3.png)

### Design Questions

**d) HF Spaces sleep vs Cloud Run scale-to-zero**

HF Spaces is slower on cold start because:
1. Uses simpler infrastructure
2. Platform is optimized for ML/Demo, not production
3. Less aggressive image caching
4. Resources are allocated on request, no pool of "warm" containers

Cloud Run is faster because:
1. Uses advanced orchestration (Knative)
2. Keeps containers in "warm" state
3. Aggressive image caching
4. Optimized for production workloads

**e) app_port: 8080**

HF default port is `7860` (standard port for Gradio and Streamlit).

QuickNotes uses port `8080`, so we need to override it using `app_port: 8080` in the README.md frontmatter.

**f) Pull vs Build inside Space**

| Aspect | Pull from ghcr.io | Build inside Space |
|--------|-------------------|-------------------|
| Speed | ✅ Fast (download ready image) | ❌ Slow (build each time) |
| Reproducibility | ✅ High (same image) | ⚠️ Depends on environment |
| HF Resources | ✅ Saves resources | ❌ Consumes more |
| Debugging | ✅ Can test locally | ❌ Need to log build process |
| Dependencies | ⚠️ Depends on ghcr.io availability | ✅ Self-contained |

**Conclusion:** Pull from ghcr.io is preferred for production-like deployments, while building inside Space is better for quick experiments.

---

