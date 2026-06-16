# Lab 3 submission

**Path:** GitHub Actions

## Task 1 — Write the PR Gate (6 pts)

### 1.1 CI config

CI config (`.github/workflows/ci.yml`) has three jobs: `vet`, `test`, `lint`.

### 1.2 Design questions

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`? What breaks otherwise?**

`ubuntu-latest` is a moving tag — it can switch to a new major version (e.g. 26.04) without notice, introducing different tool versions, kernel behaviour, or network configs. A pipeline that passed yesterday might fail today because the OS changed underneath it. Pinning makes CI deterministic: the same commit always runs in the same environment.

**b) Why split vet + test + lint into separate units? What would happen with one combined job?**

Separation gives **parallel execution** and **independent failure signals**. With one combined job, a lint failure blocks vet and test from even starting, wasting time. Separate jobs also show exactly *which* check failed in the PR status UI, and let you rerun only the failed unit.

**c) What real attack does SHA pinning prevent? Cite the date + name of the incident from Lecture 3.**

SHA pinning prevents **supply-chain compromise via tag overwrite** — if an attacker gains access to a popular action's repository and moves its `v4` tag to a malicious commit, all workflows referencing `@v4` silently get the backdoored version. The March 2025 **tj-actions/changed-files** incident is the canonical example: a compromised token allowed an attacker to replace the action's content behind its existing tag, exfiltrating secrets from every pipeline that used it unpinned.

**d) What is `permissions:` and what's the principle behind it?**

`permissions:` declares the least-privilege set of GitHub API tokens available to the workflow. The principle is **least privilege**: start with `contents: read` (read-only access to the repo) and grant only the specific permissions each job needs, so a compromised action can't escalate to writing releases, modifying issues, or accessing other repos.

### 1.3 PR gate proof

**Red CI (deliberate break):**

Commit `d8f27a6` changed `app/handlers_test.go` expected notes count from `1` to `999`. The `test` job failed while `vet` and `lint` remained green, proving the gate correctly blocks failing PRs.

![Failed CI run](artifacts/lab3/02-failed-ci.png)

**Green CI after fix:**

Commit `revert(lab3): restore test expectation, CI goes green` restored the correct value. All three jobs passed.

Green CI run: https://github.com/moflotas/DevOps-Intro/actions/runs/27642580258/

### 1.4 Branch protection

Enabled on `moflotas/DevOps-Intro` `main`:
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Required checks: `vet`, `test`, `lint`

![Branch protection](artifacts/lab3/01-branch-protection.png)

## Task 2 — Make It Fast and Smart (4 pts)

<!-- TODO -->

## Bonus Task — Pipeline Performance Investigation (2 pts)

<!-- TODO -->
