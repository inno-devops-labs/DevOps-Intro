Signed commits are used to confirm that a commit was created by a specific developer and was not modified later. This helps protect the repository from fake or substituted commits and increases trust between team members.

In GitHub, signed commits are marked as **Verified**, so anyone reviewing the code can immediately see that the author is trusted. SSH keys can be used for commit signing, which is easier to set up than classic GPG keys.

The SSH key was already present on the local machine and was added to the GitHub account. After that, Git was configured to use SSH for commit signing. As a result, a signed commit was created and successfully verified on GitHub.

Commit signing is important in DevOps workflows because code changes often go through automated pipelines and multiple environments. Being able to verify who created a commit improves security, accountability, and overall reliability of the delivery process.