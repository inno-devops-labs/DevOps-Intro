# Lab 1 — Submission: Introduction to DevOps & Git Workflow

**Author:** Alexandra Starikova-Nasibullina
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

```
1 file changed, 49 insertions(+)
create mode 100644 labs/submission1.md
```

### 1.3 Why is commit signing important in DevOps workflows?

In DevOps, commit signing is important because:

1. **Pipeline trust** — CI/CD runs code from commits. Signed commits ensure the code that is built, tested, and deployed really comes from an allowed identity, reducing supply-chain and impersonation risks.
2. **Collaboration at scale** — With many contributors and forks, the "Verified" badge (and optional branch protection requiring signed commits) gives reviewers and maintainers a clear signal that the author is who they claim to be.
3. **Traceability** — Incidents and audits often require knowing exactly who changed what. Signatures provide cryptographic evidence of authorship that cannot be forged.
4. **Policy enforcement** — Organizations can require signed commits on critical branches, so only verified changes can be merged. This supports both security and compliance.

### 1.4 Verification on GitHub

- After pushing your branch, open your PR or the commit history on GitHub.
- Find the commit you made with `git commit -S -m "..."`.
- Take a screenshot showing the **Verified** badge next to that commit.
- Paste or attach it here (or describe where you uploaded it if you submit screenshots separately).

---

## Task 2 — PR Template & Checklist

### 2.1 PR Template Location

The PR template is located at:

```
.github/pull_request_template.md
```

It is present on the **main** branch of the fork so that when opening a PR (e.g. `feature/lab1` → `main`), GitHub auto-fills the description with the template.


### 2.3 How PR Templates Improve Collaboration

- **Consistency** — Every PR has the same structure (e.g. Goal, Changes, Testing), so reviewers know where to find intent, scope, and how to verify. This reduces back-and-forth and speeds up review.
- **Checklists** — A short checklist (e.g. title, docs, no secrets) reminds authors of common requirements and gives reviewers a quick way to confirm basics are done. It also helps with self-review before requesting review.
- **Context** — Clear "Goal" and "Changes" sections make it easier for future readers (and tools) to understand why the PR exists and what was modified, improving documentation and onboarding.
- **Process** — In DevOps, PRs are the gate before merge. Standardized templates make the process repeatable and easier to automate or integrate with other tools (e.g. release notes, changelogs).


---

## Checklist (for PR description)

- [x] Task 1 done
- [x] Task 2 done

