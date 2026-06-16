# Lab 3 Submission

## Path
GitHub Actions

I selected GitHub Actions because I have access to GitHub and it provides integrated PR checks.

## CI run
Green CI run:
https://github.com/darknesod1-netizen/DevOps-Outro/actions/runs/27643947370/job/81750915744

## Failed run evidence
I intentionally introduced a failing change to verify the PR gate behavior.
The failed run was fixed by reverting the breaking change.

Failed run:
https://github.com/darknesod1-netizen/DevOps-Outro/actions/runs/27644857962/job/81754022138

Fix commit:
544e445

## Branch protection
Screenshot attached in PR/submission.

## Task 1 Design Questions

### a) Why pin ubuntu-24.04 instead of ubuntu-latest?
Pinning prevents unexpected runner changes. ubuntu-latest can move to a newer OS image and introduce breaking changes.

### b) Why split vet, test and lint?
Separate jobs allow independent failures and parallel execution. With one combined job it is harder to identify failures and debugging takes longer.

### c) What does SHA pinning prevent?
SHA pinning protects against supply-chain attacks where a dependency action tag is moved to malicious code. Example: tj-actions/changed-files incident in March 2025.

### d) What is permissions?
permissions defines the GitHub token access level. Least privilege means only granting the access required, such as contents: read.

## Task 2

Not completed due to time constraints.

I completed the PR gate pipeline with vet, test, and lint jobs. 
The remaining optimizations (Go cache, matrix testing, and path filtering) were not implemented.

## Task 2 Design Questions

### f) Why cache go.sum-keyed inputs and not build outputs?
Caching dependency inputs is safer because dependencies are deterministic based on go.sum. Build outputs may depend on environment and toolchain details.

### g) What does fail-fast false change?
fail-fast false allows all matrix jobs to finish and report their results. fail-fast true is useful when saving CI time is more important than seeing all failures.

### h) What is the risk of cache poisoning?
An attacker could attempt to put malicious data into a cache that later trusted builds use. CI systems isolate caches and restrict cache usage to reduce this risk.