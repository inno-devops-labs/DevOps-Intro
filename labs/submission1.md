## Lab 1 — Task 1

### Benefits of signing commits
Signed commits protect developers from impersonation and unauthorized changes.
They help ensure that commits are created by verified authors and were not modified after signing.
As a result, commit signing increases trust in shared repositories and preserves the authenticity and integrity of the commit history.

### Why is commit signing important in DevOps workflows?
DevOps workflows rely on automation, CI/CD pipelines, and collaboration between multiple stakeholders.
Commit signing adds an extra layer of security by verifying the author of each change.
This improves traceability, supports auditing, and helps ensure that only trusted and verified code is merged and deployed.

### Evidence of successful SSH key setup and signed commit
- An SSH signing key was generated and added to GitHub as a signing key
- Git was configured to sign commits using SSH
- A signed commit was pushed to the repository
- GitHub displays the commit with a **Verified** badge

![img.png](img.png)
### Verification
![img_2.png](img_2.png)