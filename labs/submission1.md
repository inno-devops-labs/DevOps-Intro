# Lab 1 — Submission

## Task 1 — SSH Commit Signature Verification

### 1.1 Benefits of signing commits (integrity + authenticity)
Signed commits add a cryptographic signature to the commit hash.

**Benefits:**
- **Authenticity:** reduces author spoofing (someone can fake `user.name`/`user.email`, but cannot create a valid signature without the private key).
- **Integrity:** signature is tied to the commit hash; any change to the commit invalidates verification.
- **Auditability (DevOps):** improves traceability for changes in CI/CD, IaC (Terraform/K8s), and production workflows; supports branch protection policies like “require signed commits”.

### 1.2 Evidence: signed commit + verification
![alt text](evidence.png)

### 1.3 Why is commit signing important in DevOps workflows?
- Prevents spoofed commits in protected branches (only trusted keys can sign).
- Improves supply-chain security for CI/CD (signed change provenance).
- Enables enforcement via branch protection rules: “require signed commits”.
- Helps auditing and incident response: who signed + when + what exact content.

