# Lab 1 Submission

Repository and branch
- Repo: DevOps-Intro
- Branch: feature/lab1

---

## Task 1 — SSH commit signing

### Benefits of signing commits
- Authorship proof: shows the commit was created by the holder of the signing key.
- Integrity protection: if commit content changes after signing, verification fails.
- Trust signal for reviews and automation: helps reduce impersonation and tampering risk in team workflows.

### Why commit signing is important in DevOps workflows
DevOps relies on fast collaboration and automated pipelines. Signed commits add cryptographic provenance for changes, improving auditability and reducing the risk of accepting spoofed or modified commits in code review and CI.

### Evidence of setup and signed commit

Commands used
```bash
git --version
git config --global --get gpg.format
git config --global --get user.signingkey
git config --global --get commit.gpgsign
git log --show-signature -1
````

Outputs

```text
git version 2.34.1
ssh
/home/yoba/.ssh/ssh_new_git.pub
true

commit df1c7b38fffb4d2c96e821d9dc4ee4f876ad0f2ec (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for polarevia@bk.ru with ED25519 key SHA256:YqLUphA4qs438jbSQLGZW1QL2MZ/lH6H8zU9i02xLW4
Author: vizitei-dmitri <polarevia@bk.ru>
Date:   Fri Feb 6 17:38:09 2026 +0300

    docs: trigger verified badge
```

Screenshots for Task 1

* GitHub commit page showing Verified badge
* GitHub Settings → SSH and GPG keys showing the SSH key added as a Signing key
  These screenshots are attached in the PR description.

---

## Task 2 — PR template and checklist

### Evidence PR template exists on main

* Path: `.github/pull_request_template.md` on `main` branch of my fork
* Verified by opening the file on GitHub UI on the `main` branch

### Evidence template auto-fills PR description

* Opened a PR in my fork `feature/lab1 -> main` and GitHub auto-filled the PR description with Goal, Changes, Testing and the checklist
* Screenshot is attached in the PR description

### How PR templates improve collaboration

* Standard structure ensures reviewers always receive goal, changes, and testing information.
* Checklist reduces common mistakes such as missing documentation or committing secrets.
* Less back-and-forth during review because required context is requested upfront.

### Challenges encountered

* Commits were Unverified until the SSH public key was added to GitHub as a Signing key.
* Local signature verification required configuring `gpg.ssh.allowedSignersFile`.

---

## Final submission

PR URL to course repo

* [https://github.com/inno-devops-labs/DevOps-Intro/pull/278](https://github.com/inno-devops-labs/DevOps-Intro/pull/278)

````

### 3) Save and exit nano
- Save: `Ctrl+O` then Enter
- Exit: `Ctrl+X`

### 4) Commit and push
```bash
git add labs/submission1.md
git commit -m "docs: finalize lab1 submission"
git push
````

That’s it.
