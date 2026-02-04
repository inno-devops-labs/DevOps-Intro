# Lab 1 Submission

## Task 1 — SSH Commit Signature Verification

### Why signed commits are important
Signed commits help verify the authenticity and integrity of changes in a repository.
They ensure that a commit was created by a trusted developer and was not modified
after being signed. This protects projects from impersonation, supply-chain attacks,
and unauthorized changes.

### Why commit signing is important in DevOps workflows
In DevOps workflows, many changes are automated and go through CI/CD pipelines.
Commit signing provides traceability and trust, ensuring that only verified contributors
can introduce changes into production systems. This is especially important for
infrastructure-as-code and security-sensitive repositories.

### Evidence of SSH commit signing
- SSH key configured for commit signing
- Signed commit pushed to GitHub
- Commit shows **Verified** badge on GitHub
