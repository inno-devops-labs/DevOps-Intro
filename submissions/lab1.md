# Lab 1 submission
### `curl` output:
- `GET /health`:
```json
{
    "notes": 5,
    "status": "ok"
}
```
- `GET /notes`:
```json
[
    {
        "id": 3,
        "title": "DevOps mantra",
        "body": "If it hurts, do it more often.",
        "created_at": "2026-01-15T10:10:00Z"
    },
    {
        "id": 4,
        "title": "Endpoint cheat-sheet",
        "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
        "created_at": "2026-01-15T10:15:00Z"
    },
    {
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-07T06:39:16.391846952Z"
    },
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    },
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point \u2014 env vars, signal handling, graceful shutdown.",
        "created_at": "2026-01-15T10:05:00Z"
    }
]
```
- `POST /notes`:
```json
{
    "id": 6,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-07T06:57:12.010597168Z"
}
```

### Signed commit
```
commit 6c73920a1fdc3a3e0fdee25992fce10750a28b21 (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for arsenez@cybercommunity.space with ED25519 key SHA256:2J3M7ENdm13QZIlzpxyzXRyoz6dEuk9j8zLyMQigQ40
Author: arsenez <arsenez@cybercommunity.space>
Date:   Sun Jun 7 09:41:51 2026 +0300

    docs(lab1): start submission
    
    Signed-off-by: arsenez <arsenez@cybercommunity.space>
```
![](./lab1-signed-commit.png)

### Signed commit explanation
The March 2024 XZ Utils supply chain crisis highlighted that source code and release tarballs can be subtly manipulated when a project's maintainer account is compromised or taken over by a malicious actor (like "Jia Tan"). Signed commits matter because they use cryptographic verification to guarantee a commit genuinely originated from a trusted developer rather than an impersonator or a compromised account. By establishing a clear, unforgeable chain of custody, code signing ensures that unauthorized or highly suspicious changes can be immediately flagged before they are bundled into downstream software distributions.

### GitHub Community
Starring repositories acts as a vital discovery and validation mechanism in open source, helping projects gain visibility, signal reliability, and attract potential contributors. Meanwhile, following developers fosters professional growth and team alignment by keeping you updated on industry trends, innovative coding practices, and your peers' ongoing contributions.

## Bonus: Branch protection
### Branch protection rules
![](./lab1-branch-protection.png)

### Rejection test
```log
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 221 bytes | 221.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: Review all repository rules at https://github.com/arsenez2006/DevOps-Intro/rules?ref=refs%2Fheads%2Fmain
remote: 
remote: - Changes must be made through a pull request.
remote: 
remote: - Commits must have verified signatures.
remote:   Found 1 violation:
remote: 
remote:   07c54eb205f5cc8137bdd13f58d1e5aedcf554e7
remote: 
To https://github.com/arsenez2006/DevOps-Intro.git
 ! [remote rejected] main -> main (push declined due to repository rule violations)
error: failed to push some refs to 'https://github.com/arsenez2006/DevOps-Intro.git'
```

### Reflection
If Knight Capital had enforced branch protection and required signed commits on their production deployment branch, their catastrophic 2012 automated deployment failure would have been structurally blocked. The rogue, un-updated code on the eighth server would have been rejected at the deployment gate because unsigned or unreviewed commits could not be pushed to the release branch. Additionally, the process of manually patching or "hot-fixing" live production servers on the fly would have been impossible without triggering immediate compliance alerts and cryptographic verification failures. Ultimately, these guardrails would have forced the team to use a unified, automated CI/CD pipeline, catching the configuration discrepancy before the high-frequency trading code could execute.