Signed commits are used to make sure that a commit was created by a specific developer and has not been changed afterwards. This allows other contributors to trust that the commit is authentic and really belongs to the stated author, reducing the risk of fake or replaced commits in the repository.

In GitHub, signed commits are marked as **Verified**, so anyone reviewing the code can immediately see that the author is trusted. SSH keys can be used for commit signing, which is easier to set up than classic GPG keys.

The SSH key was already available on the local machine and added to the GitHub account. Git was configured to use SSH for commit signing, and a signed commit was successfully created and verified on GitHub.

Commit signing is important in DevOps workflows because code changes often go through automated pipelines and multiple environments. Being able to verify who created a commit improves security, accountability, and overall reliability of the delivery process.