# Lab 3 — CI/CD with GitHub Actions & GitLab CI

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-CI%2FCD%20Pipelines-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Build foundational CI/CD workflows using GitHub Actions or GitLab CI: quickstart, triggers, logs, and system information.
> **Deliverable:** A PR/MR from `feature/lab3` to the course repo with `labs/submission3.md` containing run links/log snippets, pipeline YAML, and brief explanations for each task. Submit the PR/MR link via Moodle.

> **📌 Important:** Choose **ONE** platform (GitHub Actions OR GitLab CI) based on where your repository is hosted. Both platforms accomplish the same learning objectives.

---

## Overview

In this lab you will practice:
- Creating a minimal CI/CD pipeline using the official quickstart guide.
- Triggering pipelines on `push` and manually.
- Viewing run logs, understanding jobs/steps/stages, and diagnosing failures.
- Gathering runner OS/CPU/memory information from within a job.
- Documenting findings in `labs/submission3.md` with evidence (links/snippets).

**Platform Selection:**
- **GitHub users:** Follow the GitHub Actions tasks below (default instructions)
- **GitLab users:** Expand the "GitLab CI Alternative" sections for GitLab-specific instructions

---

<details>
<summary>🦊 <strong>GitLab CI Alternative - Complete Instructions (Click to Expand)</strong></summary>

## GitLab CI Tasks

### Task 1 — First GitLab CI Pipeline (6 pts)

**Objective:** Set up a basic pipeline that runs on push and prints basic info.

#### 1.1: Follow GitLab CI Quickstart

1. **Read and Implement Quickstart:**

   - Read and follow the GitLab CI [quickstart guide](https://docs.gitlab.com/ee/ci/quick_start/).
   - Create a `.gitlab-ci.yml` file in the root of your repository.
   - Document all your observations, key concepts, and steps you followed.

   <details>
   <summary>💡 Hints</summary>

   - The pipeline configuration file must be named `.gitlab-ci.yml` (not `.yaml`)
   - Place it in the repository root (same level as README.md)
   - You'll need to define at least one job with a `script` section
   - Consider using `echo`, `date`, or other simple commands to verify it's working

   </details>

#### 1.2: Test Pipeline Trigger

1. **Push Commit and Monitor:**

   - Commit and push your `.gitlab-ci.yml` file
   - Navigate to your project → **Build → Pipelines** (or CI/CD → Pipelines)
   - Observe the running pipeline
   - Click on the pipeline to see job details and logs

In `labs/submission3.md`, document:
- Link to the successful pipeline run (or screenshots)
- Key concepts learned (stages, jobs, runners, triggers)
- A short note on what caused the pipeline to trigger
- Analysis of pipeline execution process

---

### Task 2 — Manual Trigger + System Information (4 pts)

**Objective:** Add a manual trigger and capture system details from the runner.

#### 2.1: Add Manual Trigger

1. **Extend Pipeline with Manual Trigger:**

   <details>
   <summary>📚 Where to find manual trigger documentation</summary>

   - [GitLab CI YAML Reference - when:manual](https://docs.gitlab.com/ee/ci/yaml/#when)
   - [Running jobs manually](https://docs.gitlab.com/ee/ci/jobs/#run-a-manual-job)
   - Look for the `when` keyword in the documentation
   - Consider using `allow_failure: true` to prevent blocking the pipeline

   </details>

#### 2.2: Test Manual Trigger

1. **Trigger Job Manually:**

   - Push your updated `.gitlab-ci.yml`
   - Navigate to **Build → Pipelines** → Click on your pipeline
   - Find your manual job and click the play button ▶️ to run it
   - View the job logs

#### 2.3: Gather System Information

1. **Add System Information Collection:**

   - Modify your pipeline to include an additional job for gathering system information
   - Use appropriate commands to collect information about the runner, hardware specifications, and operating system details

   <details>
   <summary>💡 Useful commands and variables</summary>

   **System commands:**
   - `uname` - OS and kernel information
   - `nproc` - number of CPU cores
   - `free` - memory information
   - `df` - disk space
   - `cat /proc/cpuinfo` - detailed CPU info

   **GitLab CI variables:**
   - `$CI_RUNNER_VERSION` - Runner version
   - `$CI_RUNNER_DESCRIPTION` - Runner description
   - `$CI_JOB_ID` - Current job ID
   - `$CI_PIPELINE_ID` - Current pipeline ID
   - [Full list of predefined variables](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)

   </details>

2. **Push and Verify:**

   - Commit and push your changes
   - View the job logs to see detailed runner information

In `labs/submission3.md`, document:
- Changes made to the `.gitlab-ci.yml` file
- The gathered system information from runner
- Comparison of manual vs automatic job triggers
- Analysis of runner environment and capabilities
- Screenshots of pipeline overview and job logs

---

### GitLab CI - How to Submit

1. Create a branch for this lab and push it:

   ```bash
   git switch -c feature/lab3
   # create labs/submission3.md with your findings
   git add labs/submission3.md
   git commit -m "docs: add lab3 submission"
   git push -u origin feature/lab3
   ```

2. Open a **Merge Request (MR)** from your fork's `feature/lab3` branch → **course repository's main branch**.

3. In the MR description, include:

   ```text
   - [x] Task 1 done (GitLab CI)
   - [x] Task 2 done (GitLab CI)
   ```

4. **Copy the MR URL** and submit it via **Moodle before the deadline**.

---

### GitLab CI - Acceptance Criteria

- ✅ Branch `feature/lab3` exists with commits for each task
- ✅ File `.gitlab-ci.yml` exists in repository root
- ✅ File `labs/submission3.md` contains required outputs and analysis for Tasks 1-2
- ✅ Pipeline runs successfully on `push` and has manual jobs configured
- ✅ MR from `feature/lab3` → **course repo main branch** is open
- ✅ MR link submitted via Moodle before the deadline

---

### GitLab CI - Helpful Resources

**Official Documentation:**
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [.gitlab-ci.yml Reference](https://docs.gitlab.com/ee/ci/yaml/)
- [GitLab CI Quick Start](https://docs.gitlab.com/ee/ci/quick_start/)
- [Understanding GitLab Pipelines](https://docs.gitlab.com/ee/ci/pipelines/)

**Key Concepts:**
- **Stages:** Groups of jobs that run in sequence (test → build → deploy)
- **Jobs:** Individual tasks that run scripts
- **Runners:** Execution agents that run your jobs
- **Triggers:** Events that start pipelines (push, merge request, manual, scheduled)

**GitLab CI Tips:**
1. Pipeline files must be named `.gitlab-ci.yml` in repository root
2. Verify pipeline syntax using GitLab's built-in CI Lint (CI/CD → Editor → Validate)
3. Monitor pipeline runs in Build → Pipelines
4. Check job logs immediately after pushing to diagnose issues
5. Use `when: manual` to create manually-triggered jobs

**GitLab-specific CI Variables:**
- `$CI_COMMIT_SHA` - Commit hash
- `$CI_COMMIT_BRANCH` - Branch name
- `$CI_PIPELINE_ID` - Pipeline ID
- `$CI_JOB_ID` - Job ID
- `$CI_RUNNER_VERSION` - Runner version
- [Full list of predefined variables](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)

</details>

---

## Tasks (GitHub Actions)

### Task 1 — First GitHub Actions Workflow (6 pts)

**Objective:** Set up a basic workflow that runs on push and prints basic info.

#### 1.1: Follow GitHub Actions Quickstart

1. **Read and Implement Quickstart:**

   - Read and follow the GitHub Actions [quickstart](https://docs.github.com/en/actions/quickstart).
   - Document all your observations, key concepts, and steps you followed.

#### 1.2: Test Workflow Trigger

1. **Push Commit and Monitor:**

   - Push a commit to trigger the workflow.
   - Observe the run details and logs in the Actions tab.

In `labs/submission3.md`, document:
- Link to the successful run (or screenshots).
- Key concepts learned (jobs, steps, runners, triggers).
- A short note on what caused the run to trigger.
- Analysis of workflow execution process.

---

### Task 2 — Manual Trigger + System Information (4 pts)

**Objective:** Add a manual trigger and capture system details from the runner.

#### 2.1: Add Manual Trigger

1. **Extend Workflow with Manual Trigger:**

   <details>
   <summary>📚 Where to find manual trigger documentation</summary>

   - [Triggering a workflow - GitHub Docs](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#defining-inputs-for-manually-triggered-workflows)
   - Look for `workflow_dispatch` event in the documentation
   - Inputs for manually triggered workflows are not needed, so you can skip them

   </details>

#### 2.2: Test Manual Dispatch

1. **Dispatch Workflow Manually:**

   - Dispatch the workflow manually from the GitHub UI (Actions → your workflow → Run workflow).

#### 2.3: Gather System Information

1. **Add System Information Collection:**

   - Modify your workflow to include an additional step for gathering system information.
   - Use the appropriate actions and steps to collect information about the runner, hardware specifications, and operating system details.

In `labs/submission3.md`, document:
- Changes made to the workflow file.
- The gathered system information from runner.
- Comparison of manual vs automatic workflow triggers.
- Analysis of runner environment and capabilities.

---

## How to Submit

1. Create a branch for this lab and push it:

   ```bash
   git switch -c feature/lab3
   # create labs/submission3.md with your findings
   git add labs/submission3.md
   git commit -m "docs: add lab3 submission"
   git push -u origin feature/lab3
   ```

2. **Open a PR (GitHub) or MR (GitLab)** from your fork's `feature/lab3` branch → **course repository's main branch**.

3. In the PR/MR description, include:

   ```text
   Platform: [GitHub Actions / GitLab CI]

   - [x] Task 1 done
   - [x] Task 2 done
   ```

4. **Copy the PR/MR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab3` exists with commits for each task.
- ✅ File `labs/submission3.md` contains required outputs and analysis for Tasks 1-2.
- ✅ **GitHub Actions:** Workflow runs successfully on `push` and via `workflow_dispatch`. File `.github/workflows/*.yml` exists.
- ✅ **GitLab CI:** Pipeline runs successfully on `push` and has manual jobs. File `.gitlab-ci.yml` exists.
- ✅ PR/MR from `feature/lab3` → **course repo main branch** is open.
- ✅ PR/MR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                      | Points |
| ---------------------------------------------- | -----: |
| Task 1 — First workflow setup + run            |   **6**|
| Task 2 — Manual trigger + system information   |   **4**|
| **Total**                                      |  **10**|

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission3.md`.
- Include both command outputs and written analysis for each task.
- Document pipeline/workflow setup process and system information gathering.
- Include links to successful pipeline/workflow runs or screenshots as evidence.
- Clearly indicate which platform you used (GitHub Actions or GitLab CI) in your submission.

<details>
<summary>📚 Helpful Resources - GitHub Actions</summary>

**Official Documentation:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Understanding GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)

</details>

<details>
<summary>📚 Helpful Resources - GitLab CI</summary>

**Official Documentation:**
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [.gitlab-ci.yml Reference](https://docs.gitlab.com/ee/ci/yaml/)
- [GitLab CI Quick Start](https://docs.gitlab.com/ee/ci/quick_start/)
- [Understanding GitLab Pipelines](https://docs.gitlab.com/ee/ci/pipelines/)

</details>

<details>
<summary>💡 GitHub Actions Tips</summary>

1. Ensure workflow files are placed in `.github/workflows/` directory.
2. Verify workflow syntax using GitHub's built-in validator.
3. Monitor workflow runs in the Actions tab for debugging.
4. Check the Actions tab immediately after pushing to see if the workflow triggered.

</details>

<details>
<summary>💡 GitLab CI Tips</summary>

1. Pipeline file must be named `.gitlab-ci.yml` in repository root.
2. Verify pipeline syntax using GitLab's CI Lint (CI/CD → Editor → Validate).
3. Monitor pipeline runs in Build → Pipelines for debugging.
4. Check the Pipelines page immediately after pushing to see if the pipeline triggered.
5. Use `when: manual` to create manually-triggered jobs.

</details>