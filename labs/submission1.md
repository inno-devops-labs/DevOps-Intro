# Lab 1 — Submission: Introduction to DevOps & Git Workflow

**Author:** [Your Name]
**Branch:** `feature/lab1`

---

## Task 1 — SSH Commit Signature Verification

### 1.1 Summary: Benefits of Signing Commits

**Why sign commits?**

- **Authenticity** — Recipients can verify that the commit was made by the holder of the private key (you), not by an impersonator. This matters in shared repos and when merging code from forks.
- **Integrity** — The signature is bound to the exact commit content (tree, parent, author, message). Any change to the commit breaks the signature, so tampering is detectable.
- **Trust in DevOps** — In CI/CD and code review, signed commits let teams and automation trust that the code came from an authorized identity. Required signing on protected branches is a common policy.
- **Audit and compliance** — Organizations can prove who authored or approved which changes, which is important for regulated environments and blameless postmortems.

*References: [GitHub Docs — About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [Atlassian — Sign commits with SSH](https://confluence.atlassian.com/bitbucketserver/sign-commits-and-tags-with-ssh-keys-1305971205.html).*

### 1.2 Evidence of SSH Key Setup and Signed Commit

**Git configuration for SSH signing:**

```bash
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgSign true
git config --global gpg.format ssh
```

**Verification (run and paste your output below):**

```bash
git config --global --list | grep -E 'signing|gpg|commit'
```

```
user.signingkey=/home/lexi/.ssh/id_ed25519.pub
commit.gpgsign=true
gpg.format=ssh
```

**Signed commit:**

```bash
git commit -S -m "docs: add commit signing summary"
```


