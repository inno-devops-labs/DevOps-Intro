# Lab 3 submission
### The path
I have chosen GitHub path, because it works for me, and I already have an account.
### Branch protection rule
![](./lab3-branch-protection.png)
### Failed run + fix
Failed run prevents from merging:\
![](./lab3-blocked-merge.png)

Failed run log:\
![](./lab3-failed-run-log.png)

After fix:\
![](./lab3-merge-allowed.png)

[Link to the green run](https://github.com/arsenez2006/DevOps-Intro/actions/runs/27502050568)
### Design questions
- a) `latest` tag is a moving target. When GitHub upgrades the underlying runner image version, our workflow inherits it. Sudden updates may introduce breaking changes in pre-installed software, leading to pipeline failures.
- b) One combined job runs sequentially, while separate units run concurrently, significantly reducing total pipeline execution time. If a single formatting commit triggers a combined job, where the lint error appears at the end of a 15-minute test suite run, the entire pipeline fails late. Furthermore, a failure in an early step might prevent subsequent steps from running at all, hiding other errors.
- c) SHA pinning prevents Supply Chain Attacks via tag mutability. Tags may be overwritten by a malicious actor, making our pipeline inherit the compromised code (In March 2025, the popular tj-actions/changed-files action was compromised; the attacker rewrote all tags to a malicious version, leaking secrets from thousands of public CI runs). A cryptographic SHA is immutable and cannot be spoofed.
- d) `permissions:` is the runner access configuration for workflows. On workflows initiation, GitHub automatically issues a short-lived access token for the runner. The runner access token permissions may be configured the `permissions:` directive. By explicitly defining permissions, we ensure that even if an attacker successfully injects malicious code into the runner, they cannot abuse the token to gain full access to the repository.