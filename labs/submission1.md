# Lab 1 Submission

## Task 1
### 1.1: Benefits of Signed Commits
Commit signing provides non-repudiation. In git, anyone can spoof a username and email. Signing with an SSH key ensures that the commit definitely came from a specific person who holds the private key, preventing unauthorized or malicious code from being impersonated as a trusted developer.

### 1.2: Importance in DevOps
In DevOps workflows, automated CI/CD pipelines often trigger based on new commits. If an attacker can push code pretending to be a senior developer, the system might automatically deploy a backdoor. Signed commits create a chain of trust that ensures only verified code moves through the pipeline.

### 1.3: Evidence
- **SSH Key Setup:** Configured `gpg.format` to `ssh` and linked my public key.
- **Verification:** My commits on GitHub now display the "Verified" badge.
![Verification](https://i.postimg.cc/25KNgd4N/image.png)

---

## Task 2
### 2.1: PR Template Analysis
Pull Request templates improve collaboration by standardizing the information shared during a code review. They ensure that every developer explains the *why* (Goal) and the *how* (Changes/Testing) before a reviewer even looks at the code. This reduces review time and ensures quality standards (like checking for secrets) are met every time.

### 2.2: Implementation Notes
- Created `.github/pull_request_template.md` on the main branch for bootstrapping.
- Verified that the template auto-fills the description field when opening a new Pull Request.
![PR Template](https://i.postimg.cc/dQ7GMqKK/image.png)
