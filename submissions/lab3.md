# Lab 3 submission

**Path: GitHub Actions** - I picked it because my fork and Labs 1-2 already live on GitHub, so a SHA-pinned `.github/workflows/ci.yml` runs natively with no extra tooling.

## Task 1: PR gate

CI config: [.github/workflows/ci.yml](../.github/workflows/ci.yml)

Green CI run: [run 27644045591](https://github.com/danielpancake/DevOps-Intro/actions/runs/27644045591)

### 1.2 Design questions

**a) Why pin `ubuntu-24.04` instead of `ubuntu-latest`?**
`ubuntu-latest` can change automatically when GitHub switches it to a newer Ubuntu version. That means the OS, preinstalled tools, and package versions may change without any updates to your code, potentially causing builds to fail unexpectedly.

**b) Why split vet + test + lint into separate units?**
They are independent tasks, so they can run in parallel. This reduces total pipeline time because the overall duration is roughly the time of the slowest job, not the sum of all three. Separate jobs also make failures easier to understand. You can immediately see whether the problem is a vet warning, a test failure, or a lint issue.

**c) What attack does SHA pinning prevent? (Lecture 3)**
SHA pinning protects against supply-chain attacks that exploit mutable tags or branches. Tags such as v4 can be moved to point to different code, so anyone with permission to modify the action's repository can change what your workflow runs without any changes in the repository.

**d) What is `permissions:` and the principle behind it?**
`permissions`: controls what the `GITHUB_TOKEN` can do in a GitHub Actions workflow. It lets you set access levels for resources such as repository contents, pull requests, and packages.

**e) GitLab path: stage vs job; what `dependencies:` adds**
In GitLab CI, a stage is a pipeline phase (for example, build, test, or deploy), while a job is a specific task that runs within a stage. even though stage ordering already sequences them.

### Evidence

Green run - all three required checks pass:

![green CI](image/lab3/green_ci.png)

Failed run - `test` broken on purpose ([commit](https://github.com/danielpancake/DevOps-Intro/commit/0f250b6)); `test` is red and merge is blocked. Reverted in the [fix commit](https://github.com/danielpancake/DevOps-Intro/commit/19c587c):

![blocked merge on failing test](image/lab3/ci_failure.png)

Branch protection on `main` - `vet`, `test`, `lint` required + branches must be up to date:

![branch protection](image/lab3/branch_protection.png)
