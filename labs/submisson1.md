# Lab 1 Submission

## Task 1 — SSH Commit Signature Verification

### 1.1 Benefits of Signed Commits
Signed commits proves authourship and prevent attacks by unidentified users.

### 1.2 SSH Key Setup Evidence
$ git config --global user.signingkey
C:/Users/User/.ssh/id_ed25519.pub


$ git config --global commit.gpgSign
true

$ git config --global gpg.format
ssh

### 1.3 Importance in DevOps Workflows
Commit signing is important in DevOps workflows primarily for security, traceability, and compliance.

### 1.4 Signed Commit Example
Commit hash: dca72f9d44bb95c1bf845b941cfec17966cdd6bc
https://imgur.com/a/uGabITe

## Task 2 — PR Template & Checklist

### 2.1 PR Template Creation
https://imgur.com/a/gvYqIeG

### 2.2 Template Verification
https://imgur.com/a/4K8rYZj

### 2.3 Analysis
PR templates standardize communication, reduce review time, and ensure consistency across team contributions.

### 2.4 Challenges Encountered
The main challenge was understanding that GitHub loads templates from the base repository's default branch.