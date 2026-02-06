# Lab 1 — Submission

## Task 1 — SSH Commit Signing

### Benefits of signed commits
Signed commits provide cryptographic proof that a commit was created by a trusted author and was not modified after being created. This ensures the integrity of the codebase and protects against malicious or accidental tampering with commit history. Commit signing also establishes clear authorship, which is critical in collaborative and distributed teams. In CI/CD pipelines, signed commits increase trust in automated processes by guaranteeing that only verified code is built and deployed. From a security perspective, commit signing helps prevent supply chain attacks. Overall, signed commits improve transparency, accountability, and trust in the development workflow.

### Evidence
- Screenshot showing the “Verified” badge on a signed commit in GitHub.
- SSH-based commit signing is configured using an ed25519 SSH key. Commits are created with `git commit -S`, and GitHub successfully verifies them as signed.

  <img width="1470" height="830" alt="image" src="https://github.com/user-attachments/assets/15af71a5-7781-4b44-96cc-d1adec6e61ec" />


### Why is commit signing important in DevOps workflows?
In DevOps workflows, commit signing is important because it ensures that only authenticated and trusted changes enter the codebase. It helps teams maintain a secure and auditable development process, especially when multiple contributors and automated systems are involved. Signed commits integrate well with CI/CD pipelines by adding an additional layer of trust before builds and deployments. This practice reduces the risk of unauthorized code changes and improves overall security posture.

---

## Task 2 — PR Template & Checklist

### Evidence
- Screenshot showing that the pull request description is automatically populated from `.github/pull_request_template.md`.
- The PR template file `.github/pull_request_template.md` is located on the `main` branch of the forked repository.

### How PR templates improve collaboration
PR templates standardize the information provided by contributors, making pull requests easier and faster to review. They ensure that the purpose of the change, the list of modifications, and verification steps are always documented. Checklists reduce the chance of missing important steps such as documentation updates or security checks. This leads to more consistent reviews, better communication between team members, and higher overall code quality. As a result, PR templates streamline collaboration and reduce friction in team workflows.

### Challenges
None.
