# Commit Signing (SSH)

## 1. Short Summary: Benefits of Signing Commits

Commit signing ensures the **authenticity** and **integrity** of changes in a Git repository.  
A signed commit cryptographically proves that the commit was created by the owner of a trusted key and that its contents were not altered after signing.

Key benefits:
- prevents author impersonation;
- protects against history tampering;
- increases trust in the codebase;
- supports security and audit requirements.

---

## 2. Evidence of SSH Key Setup and Signed Commit

### SSH Authentication with GitHub

```bash
ssh -T git@github.com
Hi r3based! You've successfully authenticated, but GitHub does not provide shell access.
```

## 3. Why is commit signing important in DevOps workflows?

Commit signing is important in DevOps workflows because:

**Security and Trust**

It ensures that only trusted contributors can introduce changes into the codebase.


**Auditability and Compliance**

Signed commits provide a clear and verifiable audit trail, which is essential for security reviews and compliance requirements.


**Software Supply Chain Protection**

It helps prevent malicious code injection into CI/CD pipelines through forged or compromised commits.


**Accountability**

Every change can be reliably attributed to a specific developer and cryptographic key.


Overall, commit signing is a critical control for maintaining integrity across modern DevOps pipelines.

## 4. Evidence screenshot of signed commit

![evidence](./evidence.png)