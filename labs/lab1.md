# Lab 1 — Introduction to DevOps & Git Workflow

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-DevOps%20Basics-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Learn the basic Git workflow (fork → branch → PR) and practice secure commit practices.  
> **Deliverable:** A PR from `feature/lab1` to the course repo with `labs/submission1.md` containing all checklist items completed. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Verifying commit authenticity with **SSH commit signing**.  
- Standardizing collaboration with a **PR template & checklist**.  

These are the foundation of collaboration and trust in DevOps teams.

---

## Tasks

### Task 1 — SSH Commit Signature Verification (6 pts)

**Objective:** Understand the importance of signed commits and set up SSH commit signature verification.

#### 1.1: Explore the Importance of Signed Commits

1. **Research Commit Signing Benefits:**

   - Research why commit signing is crucial for verifying the integrity and authenticity of commits.
   
   <details>
   <summary>📚 Recommended Resources</summary>
   
   - [GitHub Docs on SSH Commit Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
   - [Atlassian Guide to SSH and Git](https://confluence.atlassian.com/bitbucketserver/sign-commits-and-tags-with-ssh-keys-1305971205.html)
   
   </details>

#### 1.2: Set Up SSH Commit Signing

<details>
<summary>🔑 Option A: Generate New SSH Key (Recommended)</summary>

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Follow the prompts to save the key (default location is fine) and optionally set a passphrase.

</details>

<details>
<summary>🔑 Option B: Use Existing SSH Key</summary>

If you already have an SSH key for GitHub authentication, you can reuse it for commit signing. Just ensure it's added to your GitHub account under **Settings → SSH and GPG keys**.

</details>

1. **Configure Git for SSH Signing:**

   ```sh
   git config --global user.signingkey <YOUR_SSH_KEY>
   git config --global commit.gpgSign true
   git config --global gpg.format ssh
   ```

   Replace `<YOUR_SSH_KEY>` with your public key path (e.g., `~/.ssh/id_ed25519.pub`).

#### 1.3: Make a Signed Commit

1. **Create and Sign Commit:**

   ```sh
   git commit -S -m "docs: add commit signing summary"
   ```

In `labs/submission1.md`, document:
- A short summary explaining the benefits of signing commits.
- Evidence of successful SSH key setup and signed commit.
- Answer: "Why is commit signing important in DevOps workflows?"
- Screenshots or verification of the "Verified" badge on GitHub.

---

### Task 2 — PR Template & Checklist (4 pts)

**Objective:** Standardize pull requests with a reusable template so reviewers see the same sections and a clear checklist every time.

> ⚠️ **One-time bootstrap:** GitHub loads PR templates from the **default branch of the base repo** (your fork’s `main`). Add the template to `main` first, then open your lab PR from `feature/lab1`.

#### 2.1: Create PR Template

1. **Template Location and Setup:**

   Create a file at `.github/pull_request_template.md` in your repository.

2. **Choose Your Approach:**

   <details>
   <summary>📝 Option A: Discover and Adapt</summary>
   
   Find a concise PR template from a reputable open-source project or GitHub docs and adapt it to your needs. Look for templates that include:
   - Clear sections (Goal/Purpose, Changes, Testing)
   - A practical checklist
   - Concise format (≤ 30 lines)
   
   </details>

   <details>
   <summary>📝 Option B: Write Your Own</summary>
   
   Create a minimal template with these sections:
   
   **Sections:**
   - **Goal** — What does this PR accomplish?
   - **Changes** — What was modified?
   - **Testing** — How was it verified?
   
   **Checklist** (3 items):
   - [ ] Clear, descriptive PR title
   - [ ] Documentation/README updated (if needed)
   - [ ] No secrets or large temporary files committed
   
   Keep it short and practical (≤ 30 lines).
   
   </details>

#### 2.2: Create Lab Branch and Open PR

1. **Branch Creation:**

   <details>
   <summary>💻 Commands</summary>
   
   ```bash
   git checkout -b feature/lab1
   git add .
   git commit -m "docs: add lab1 submission stub"
   git push -u origin feature/lab1
   ```
   
   </details>

#### 2.3: Verify Template Application

1. **Template Verification:**

   - Open a PR from `feature/lab1` → `main` **in your fork**.
   - The PR **description auto-fills** with your sections and the **3-item checklist**.
   - Fill in *Goal / Changes / Testing* and tick the checkboxes.

In `labs/submission1.md`, document:
- Screenshot of PR template auto-filling the description.
- Evidence that `.github/pull_request_template.md` exists on main branch.
- Analysis of how PR templates improve collaboration.
- Note any challenges encountered during setup.

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab1
   # create labs/submission1.md with your findings
   git add labs/submission1.md
   git commit -m "docs: add lab1 submission"
   git push -u origin feature/lab1
   ```

2. Open a PR from your fork's `feature/lab1` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab1` exists with commits for each task.
- ✅ File `labs/submission1.md` contains required outputs and analysis for Tasks 1-2.
- ✅ At least one commit shows **"Verified"** (signed via SSH) on GitHub.
- ✅ File `.github/pull_request_template.md` exists on the **main** branch.
- ✅ PR from `feature/lab1` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                   | Points |
| ------------------------------------------- | -----: |
| Task 1 — SSH commit signing setup + summary |  **6** |
| Task 2 — PR template & checklist in effect  |  **4** |
| **Total**                                   | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission1.md`.
- Include both command outputs and written analysis for each task.
- Document template setup process and verification steps.
- Ensure commit signing is working correctly with verification screenshots.

<details>
<summary>🔒 Security Notes</summary>

1. Ensure the email on your commits matches your GitHub account for proper verification.
2. Keep SSH keys secure and never commit private keys to repositories.
3. Verify `gpg.format` is set to `ssh` for proper signing configuration.
4. Use a passphrase for your SSH keys in production environments.

</details>

<details>
<summary>📋 Template Best Practices</summary>

1. Confirm the path is `.github/pull_request_template.md` **on `main`** before opening the PR.
2. Re-open the PR description editor after adding the template if it didn't auto-fill.
3. Keep templates short—reviewers read many PRs, concise templates get filled, long ones get ignored.
4. Test your template by opening a test PR before submitting the lab.

</details>
