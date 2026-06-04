# Lab 1 submission

## Task 1 — SSH Commit Signing & QuickNotes

### QuickNotes: `curl` output

**`GET /health`**

```text
markovav@markovav-mac DevOps-Intro % curl -s http://localhost:8080/health | python3 -m json.tool
{
    "notes": 4,
    "status": "ok"
}
```

**`GET /notes`**

```text
markovav@markovav-mac DevOps-Intro % curl -s http://localhost:8080/notes  | python3 -m json.tool

[
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    },
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point \u2014 env vars, signal handling, graceful shutdown.",
        "created_at": "2026-01-15T10:05:00Z"
    },
    {
        "id": 3,
        "title": "DevOps mantra",
        "body": "If it hurts, do it more often.",
        "created_at": "2026-01-15T10:10:00Z"
    },
    {
        "id": 4,
        "title": "Endpoint cheat-sheet",
        "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
        "created_at": "2026-01-15T10:15:00Z"
    }
]
```

**`POST /notes`**

```text
markovav@markovav-mac DevOps-Intro % curl -s -X POST http://localhost:8080/notes \              
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-04T23:00:29.863745Z"
}
```

---

### Signed commit: `git log --show-signature -1`

```text
markovav@markovav-mac DevOps-Intro % git log --show-signature -1

commit fe9dd4d35fe6aa4f84caf6a472b5563b65acca79 (HEAD -> feature/lab1)
Good "git" signature for me@markovav.ru with RSA key SHA256:1v0b9seRUOWIYpA8U+rk+m+rYSp3XafJ2Ge82CsZrdY
Author: Andrei Markov <me@markovav.ru>
Date:   Fri Jun 5 01:42:15 2026 +0300

    docs(lab1): start submission
    
    Signed-off-by: Andrei Markov <me@markovav.ru>
```

**Local verification issue:** The first `git log --show-signature -1` printed `gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification` and reported **No signature**, even though the commit was created with `-S`. SSH signing was enabled (`gpg.format ssh`, `commit.gpgsign true`), but Git had no local trust file mapping my email to the public key used for verification.

**Fix:** I created `~/.ssh/allowed_signers` with a line in the form `email namespaces="git" ssh-rsa AAAA...` (matching the key in `user.signingkey`), then set `git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers`. After that, the same commit showed **Good "git" signature** locally — the screenshot below matches that second run.

![git log — Good signature](attachments/lab1/signature.png)

---

### Verified badge (GitHub / GitLab)

![Verified badge on PR or commit page](attachments/lab1/verified_sign.png)

---

### Why signed commits matter

Anyone can set arbitrary `user.name` and `user.email` in Git without proof of identity. In March 2024, the xz-utils backdoor incident showed how a long-trusted maintainer account (`JiaT75`) could slip malicious code into a dependency used by millions of Linux systems — a supply-chain attack that signed commits and provenance are meant to surface early ([Lecture 1](https://github.com/inno-devops-labs/DevOps-Intro/blob/main/lectures/lec1.md), Slide 16). A signed commit is a cryptographic claim that the holder of your SSH (or GPG) key actually authored that revision, so platforms can show **Verified** and reviewers can reject unauthenticated history before it merges.

---

## Task 2 — Pull Request Template & First PR

PR template added on fork `main`: `.github/pull_request_template.md`
