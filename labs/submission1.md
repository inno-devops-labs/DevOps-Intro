# SSH Commit Signature Verification

## Benefits of Signing Commits
Commit signing provides cryptographic verification that a commit was created by the claimed author and has not been altered. It improves authenticity, integrity, and trust in collaborative repositories. Signed commits help prevent impersonation and strengthen overall repository security.

---

## Evidence of SSH Key Setup and Signed Commit

### SSH key generated
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Git configured for SSH signing
```bash
git config --global user.signingkey ~/.ssh/id_ed25519.pub  
git config --global commit.gpgSign true  
git config --global gpg.format ssh  
```

### Signed commit created
```bash
git commit -S -m "docs: add commit signing summary"
```

### Verification
```bash
git log --show-signature -1
```

Example output:
```bash
Good "git" signature for your_email@example.com with ED25519 key
```

---

## Why is commit signing important in DevOps workflows?
Commit signing ensures that only verified and trusted contributors can push code into the repository and CI/CD pipeline. It prevents malicious or unauthorized changes. This helps maintain secure, stable, and trustworthy deployments in DevOps environments.

---

## GitHub Verification