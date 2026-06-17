# Lab 1 — DevOps Foundations: Fork, Sign, and Open Your First PR

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-DevOps%20Foundations-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-Git%20%2B%20QuickNotes-informational)

> **Goal:** Get the QuickNotes project running on your machine, configure SSH commit signing, add a PR template, and open your first pull request.
> **Deliverable:** A PR from `feature/lab1` to the course repository with `submissions/lab1.md`. Submit the PR link via Moodle.

---

## Overview

In this lab you will:
- Fork the QuickNotes course repository (on **GitHub *or* GitLab** — your choice)
- Run QuickNotes locally and confirm it works
- Configure **SSH commit signing** so your commits show "Verified" on GitHub / GitLab
- Add a **pull request template** so reviewers see structured PR descriptions
- Engage with the open-source community as proof of joining the broader engineering culture

> **You don't write QuickNotes.** It's already in `app/` — a small Go service you will package, ship, monitor, and harden across the next 10 labs.

---

## Project State

**Starting point:** A freshly forked course repo. QuickNotes (`app/`) is provided.

**After this lab:** Your fork has a `feature/lab1` branch with `submissions/lab1.md`, your commits show a "Verified" badge, and you've opened a PR to the upstream course repository.

---

## Prerequisites

Install on your machine (versions are floors, newer is fine):
- Git **2.49+** (`git --version`)
- Go **1.24+** (`go version`)
- An OpenSSH client (`ssh -V`)
- A GitHub *or* GitLab account with SSH key uploaded

---

## Task 1 — SSH Commit Signing & First Signed Commit (6 pts)

**Objective:** Configure Git to sign every commit with an SSH key so reviewers can verify the commit really came from you.

### 1.1: Fork the Course Repository

Pick **one** path that works for you:

- 🐙 **GitHub:** `https://github.com/inno-devops-labs/DevOps-Intro` → click **Fork**
- 🦊 **GitLab:** clone-mirror at `https://gitlab.pg.innopolis.university/d.creed/DevOps-Intro` → click **Fork**

Clone your fork locally and add the upstream remote:

```bash
git clone git@github.com:YOUR_USERNAME/DevOps-Intro.git
cd DevOps-Intro
git remote add upstream git@github.com:inno-devops-labs/DevOps-Intro.git
git fetch --all
```

### 1.2: Run QuickNotes

```bash
cd app/
go run .
```

In another terminal:

```bash
curl -s http://localhost:8080/health | python3 -m json.tool
curl -s http://localhost:8080/notes  | python3 -m json.tool
curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
```

You should see 4 seed notes, then 5 after the POST. Capture the output for your submission.

### 1.3: Configure SSH Signing

Git ≥ 2.34 supports SSH signing natively — no GPG keyring needed:

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub   # or your key path
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

Now register the key on the platform. GitHub treats **Authentication** and **Signing** as *separate* roles for the same key, so you add it under both:

- **Authentication Key** — lets you `clone` / `fetch` / `push` over SSH (`git@github.com:…`). If you cloned over HTTPS, or have never seen `ssh -T git@github.com` greet you by name, you don't have one configured yet — add it now or the `upstream` SSH remote will fail in Lab 2.
- **Signing Key** — gives your commits the **Verified** badge.

- 🐙 GitHub: Settings → SSH and GPG keys → **New SSH key** → add the **same** `~/.ssh/id_ed25519.pub` **twice**, once with Key type **Authentication Key** and once with **Signing Key**.
- 🦊 GitLab: Profile → SSH Keys → a single key with **Usage type: Authentication & signing** covers both.

Confirm authentication works before moving on:

```bash
ssh -T git@github.com
# expect: Hi YOUR_USERNAME! You've successfully authenticated...
```

### 1.4: Make a Signed Commit

```bash
git switch -c feature/lab1
mkdir -p submissions
echo "# Lab 1 submission" > submissions/lab1.md
git add submissions/lab1.md
git commit -S -s -m "docs(lab1): start submission"
```

Verify the signature locally:

```bash
git log --show-signature -1
# look for: Good "git" signature for ...
```

Push and confirm the **Verified** badge appears on the GitHub / GitLab UI:

```bash
git push -u origin feature/lab1
```

### 1.5: Document in `submissions/lab1.md`

Include:
- Output of `curl` against `/health`, `/notes`, and `POST /notes`
- Output of `git log --show-signature -1` showing **Good** signature
- A screenshot of the Verified badge on your platform's PR/commit page
- A 2-3 sentence explanation: *why* signed commits matter (referencing the xz-utils March 2024 story from Lecture 1)

---

## Task 2 — Pull Request Template & First PR (3 pts)

**Objective:** Add a `.github/pull_request_template.md` (or GitLab equivalent) and open your first PR using it.

### 2.1: Add the Template

⚠️ **One-time bootstrap:** GitHub loads PR templates from the **default branch** of the base repo. Add the template to `main` first, then open your lab PR.

On your **main** branch in your fork:

```bash
git switch main
mkdir -p .github
cat > .github/pull_request_template.md << 'EOF'
## Goal
<!-- What does this PR accomplish? 1 sentence. -->

## Changes
- 

## Testing
<!-- How did you verify it? -->

## Checklist
- [ ] Title is a clear sentence (≤ 70 chars)
- [ ] Commits are signed (`git log --show-signature`)
- [ ] `submissions/labN.md` updated
EOF
git add .github/pull_request_template.md
git commit -S -s -m "docs: add PR template"
git push origin main
```

GitLab variant: file lives at `.gitlab/merge_request_templates/Default.md` (same content).

### 2.2: Open the Lab PR

```bash
git switch feature/lab1
# add the rest of your submission notes
git add submissions/lab1.md
git commit -S -s -m "docs(lab1): finish submission"
git push origin feature/lab1
```

Open a PR from your fork's `feature/lab1` → **course repo's `main`**. Confirm:
- The PR description auto-populated with your template sections
- All checkboxes filled
- Every commit on the PR shows **Verified**

---

## Task 3 — GitHub Community Engagement (1 pt)

**Objective:** Explore GitHub's social features that support collaboration and discovery.

**Actions Required:**
1. **Star** the course repository
2. **Star** the [simple-container-com/api](https://github.com/simple-container-com/api) project — a promising open-source tool for container management
3. **Follow** your professor and TAs on GitHub:
   - Professor: [@Cre-eD](https://github.com/Cre-eD)
   - TA: [@Naghme98](https://github.com/Naghme98)
   - TA: [@pierrepicaud](https://github.com/pierrepicaud)
4. **Follow** at least 3 classmates from the course

**Add to `submissions/lab1.md`:**

A "GitHub Community" section with 1-2 sentences explaining:
- Why starring repositories matters in open source
- How following developers helps in team projects and professional growth

<details>
<summary>💡 GitHub Social Features</summary>

**Why Stars Matter:**
- Stars help you bookmark interesting projects for later reference
- Star count indicates project popularity and community trust
- Starred repos appear in your GitHub profile, showing your interests
- Stars encourage maintainers and help projects gain visibility

**Why Following Matters:**
- See what other developers are working on
- Discover new projects through their activity
- Build professional connections beyond the classroom
- Stay updated on classmates' work for future collaboration

</details>

> **Why this task exists:** DevOps is collaborative by definition. The discipline includes participating in the broader ecosystem — not just consuming it.

---

## Bonus Task — Branch Protection & Required Signed Commits (2 pts)

**Objective:** Enforce signed commits as a branch protection rule on your fork's `main` — demonstrate the policy by trying to bypass it.

### B.1: Configure branch protection on `main`

On GitHub (Settings → Branches → Add rule for `main`):
- ☑️ **Require signed commits**
- ☑️ **Require a pull request before merging**
- ☑️ **Require linear history**

On GitLab (Settings → Repository → Protected branches): equivalent options under push rules.

### B.2: Try to break the rule

```bash
git switch main
# disable signing temporarily
git commit -S=false -s --allow-empty -m "test: unsigned commit (should fail)"
git push origin main
# expected: remote rejects with "must be signed" error
```

Capture the rejection message. Then **re-enable** signing and verify everything still works.

### B.3: Document

In `submissions/lab1.md`:
- Screenshot of the branch protection rules page
- The exact `remote: error:` line when you tried the unsigned push
- A 3-4 sentence reflection: *what would Knight Capital's deploy day have looked like with branch protection + required signing on the prod deploy branch?*

---

## How to Submit

1. Ensure `submissions/lab1.md` has sections for Task 1, Task 2, Task 3, and Bonus (if attempted)
2. Open a PR from your fork's `feature/lab1` → **course repository's main**
3. Fill in the PR template; tick the checklist
4. Copy the PR URL and submit via **Moodle before the deadline**

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ QuickNotes runs locally; you have `curl` output for `/health`, `/notes`, and `POST /notes`
- ✅ `git log --show-signature -1` shows **Good "git" signature**
- ✅ At least one commit on the PR shows **Verified** badge
- ✅ Submission includes a short explanation of *why* signing matters

### Task 2 (3 pts)
- ✅ `.github/pull_request_template.md` (or GitLab equivalent) exists on `main`
- ✅ Your PR description auto-populated from the template (visible in the PR diff or screenshot)
- ✅ Template checklist items are filled

### Task 3 (1 pt)
- ✅ Starred course repo and simple-container-com/api
- ✅ Following professor, TAs, and 3+ classmates
- ✅ GitHub Community section in submission

### Bonus Task (2 pts)
- ✅ Branch protection rules screenshot
- ✅ Rejection message from the unsigned-push attempt
- ✅ Written reflection (3-4 sentences)

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — SSH signing + QuickNotes run | **6** | Valid signature, Verified badge, curl outputs, short rationale |
| **Task 2** — PR template + first PR | **3** | Template on main, auto-population evidence, checklist filled |
| **Task 3** — GitHub community engagement | **1** | Stars, follows, and written explanation |
| **Bonus Task** — Branch protection + signed-only enforcement | **2** | Rules screenshot, rejection message, reflection |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **PR template doesn't auto-populate** — make sure the template is on `main` *before* opening the PR
- 🪤 **Commits show "Unverified"** — the key must also be added as a **Signing Key** on GitHub; an Authentication Key alone won't verify commits (they're separate roles — see §1.3)
- 🪤 **`git@github.com: Permission denied (publickey)` on clone/fetch/push** — the *reverse* gap: your key is registered for signing but not as an **Authentication Key**. Add it as Authentication too (§1.3) and confirm with `ssh -T git@github.com`. Quick unblock for the *public* upstream: `git remote set-url upstream https://github.com/inno-devops-labs/DevOps-Intro.git`
- 🪤 **`git push` rejected on `main`** — that's the bonus rule working as designed; push to `feature/lab1` instead
- 🪤 **`gpg.format=ssh` ignored** — confirm Git ≥ 2.34: `git --version`
- 🪤 **Pushed to the wrong branch** — `git switch feature/lab1` before `git push`
- 🪤 **PR opened against your fork's main, not the course main** — the base repo selector at the top of the PR-create page is the key

---

## Guidelines

- Submission documents are part of your engineering portfolio — write them as if a future employer will read them
- Include both **command output** and **written analysis** for each task
- Screenshots are encouraged for visual evidence (Verified badges, branch protection rules)
- Never paste real secrets, private SSH keys, or production data

<details>
<summary>🔒 Security Notes</summary>

1. The SSH private key (`~/.ssh/id_ed25519`) should **never** be committed — `.gitignore` it
2. Your email on commits must match your GitHub/GitLab account for the Verified badge
3. Use a passphrase on your SSH key in any environment you care about
4. The Bonus task's branch protection is a small example of the same pattern that prevents Knight-Capital-style incidents at scale

</details>

<details>
<summary>📋 Template Best Practices</summary>

1. Path must be exactly `.github/pull_request_template.md` (singular) — `.github/PULL_REQUEST_TEMPLATE.md` also works
2. Keep templates short — reviewers ignore long ones
3. Test your template by opening a *draft* PR before the real submission
4. If the template doesn't appear, your fork's `main` may not have the file — re-check the path on GitHub's web UI

</details>

---

## Resources

- 📖 [GitHub — Signing commits with SSH](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- 📖 [GitLab — Sign commits with SSH](https://docs.gitlab.com/ee/user/project/repository/signed_commits/ssh.html)
- 📖 [Git 2.34 release notes — SSH signing](https://github.blog/2021-11-15-highlights-from-git-2-34/)
- 📝 [Pro Git, Chapter 6 (Hosted Git Services)](https://git-scm.com/book/en/v2/GitHub-Account-Setup-and-Configuration)
- 🎥 [Solomon Hykes's PyCon 2013 Docker demo](https://www.youtube.com/watch?v=wW9CAH9nSLs) (for cultural context — DevOps history)
