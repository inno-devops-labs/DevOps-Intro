# Lab 1 — DevOps & Git Workflow Submission

## Task 1 — SSH Commit Signature Verification

### Why Commit Signing Matters
Commit signing is used to verify the authenticity and integrity of commits.
A signed commit proves that the changes were created by a trusted author
and were not altered after being pushed. In DevOps workflows, this helps
prevent impersonation, protects the codebase from tampering, and increases
trust in collaborative and CI/CD environments.

### SSH Setup Evidence
- An SSH key was generated and added to my GitHub account.
- Git was configured to use SSH for commit signing:
  - `gpg.format=ssh`
  - `commit.gpgSign=true`
  - `user.signingkey` set to the SSH public key.
- A signed commit was created and pushed successfully.


### Why Commit Signing Is Important in DevOps
Commit signing ensures accountability and trust by verifying the identity
of contributors. This is critical in DevOps workflows where automated
pipelines rely on the integrity of source code. Signed commits reduce the
risk of malicious code injection and help teams maintain secure and
auditable development practices.

### Verification
![alt text](Screenshot_20260203_163117.png)

---

