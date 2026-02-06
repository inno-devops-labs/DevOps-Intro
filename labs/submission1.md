# Lab 1 Submission

Repository and branch
- Repo: DevOps-Intro
- Branch: feature/lab1

---

## Task 1 — SSH commit signing

### Benefits of signing commits
- Authorship proof: shows the commit was created by the holder of the signing key.
- Integrity protection: if commit content changes after signing, verification fails.
- Trust signal for reviews and automation: helps reduce impersonation and tampering risk in team workflows.

### Why commit signing is important in DevOps workflows
DevOps relies on fast collaboration and automated pipelines. Signed commits add cryptographic provenance for changes, improving auditability and reducing the risk of accepting spoofed or modified commits in code review and CI.

### Evidence of setup and signed commit

Commands
```bash
git --version
git config --global --get gpg.format
git config --global --get user.signingkey
git config --global --get commit.gpgsign
git log --show-signature -1

