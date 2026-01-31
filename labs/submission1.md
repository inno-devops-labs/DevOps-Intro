# Lab 1 Submission

## Short Summary

Without commit signing, anyone can fake a commit by setting a name and email, for example pretending to be Yann LeCun. Git will accept it.

With commit signing, this is not possible: without the real private key, the commit cannot be verified and GitHub will mark it as Unverified.

Signing commits proves real authorship and protects commits from being modified.


## Evidence of Signed Commit

![SSH Signing Keys](labs/img/ssh_keys.png)

The screenshot shows the SSH key added in GitHub. This is required for GitHub to verify signed commits.
