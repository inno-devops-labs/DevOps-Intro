## Task 1 — SSH commit signing

Signed commits are used to confirm that a commit was created by a specific developer and was not modified later. This helps protect the repository from fake or substituted commits and increases trust between team members.

In GitHub, signed commits are marked as **Verified**, so anyone reviewing the code can immediately see that the author is trusted. SSH keys can be used for commit signing, which is easier to set up than classic GPG keys.

The SSH key was already present on the local machine and was added to the GitHub account. After that, Git was configured to use SSH for commit signing. As a result, a signed commit was created and successfully verified on GitHub.

Commit signing is especially important in DevOps workflows, where code often passes through automated pipelines and multiple stages before deployment. Verifying the author of each commit helps maintain accountability and reduces the risk of untrusted changes entering the delivery process.

![alt text](image.png)

---

## Task 2 — PR template & checklist

A pull request template was created in the `.github/pull_request_template.md` file on the `main` branch. When opening a pull request, the description is automatically filled with the required sections and checklist, which confirms that the template is working correctly.

The pull request had already been created earlier, so the final confirming changes were committed directly to the `main` branch to demonstrate that the template setup functions as expected.

![alt text](image-1.png)
