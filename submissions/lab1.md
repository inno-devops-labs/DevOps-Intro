# Lab 1 submission

## Task 1

---
`git log --show-signature -1`

```
commit 9da775a392ec1a9834544402d9260ff7e45cb67e (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for danil.2006@list.ru with ED25519 key SHA256:xBYpXoDFi9CwxWco0tgFXy+0HSD4NxXrb3qsNsdqQY0
Author: Danil Khasanshin <danil.2006@list.ru>
Date:   Sat Jun 6 19:47:49 2026 +0300

    docs(lab1): start submission

    Signed-off-by: Danil Khasanshin <danil.2006@list.ru>

```

---

`curl -s http://localhost:8080/health | python3 -m json.tool`

```
{
    "notes": 5,
    "status": "ok"
}
```

---

`curl -s http://localhost:8080/notes | python3 -m json.tool`

```
[
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
    },
    {
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-06T15:21:24.440638Z"
    },
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    }
]
```

---

```
curl -s -X POST http://localhost:8080/notes \ 
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
```

```
{
    "id": 6,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-06T17:11:59.93711Z"
}
```

---

### GitHub Verified badge

![Verified badge](../docs/screenshots/verified_badge.png)

---

### Why signed commits matter

By default, Git does not verify an author's identity: anyone can configure an arbitrary name and email address. A signed commit provides a cryptographic proof that the commit was created by the holder of a specific private key, improving code provenance and giving reviewers an additional trust signal. The xz-utils backdoor discovered in March 2024 showed why software supply chains require verifiable provenance; commit signing does not guarantee that code is safe, but it makes changes easier to attribute and audit.

## Task 2

Created PR

## Task 3

Starring repositories helps developers bookmark useful projects and increases their visibility in the open-source ecosystem. Following developers makes it easier to discover their work, stay aware of team activity, and build professional connections!

## Bonus task

### Enabled rules

- Require signed commits
- Require a pull request before merging
- Require linear history

### Screenshots

![Settings 1](../docs/screenshots/bonus-settings.png)
![Settings 2](../docs/screenshots/bonus-settings-2.png)
![Error Example](../docs/screenshots/bonus-settings-3.png)

Initially, GitHub reported that the unsigned commit violated the configured
rules but allowed the repository owner to bypass them. After enabling the
option that prevents bypassing the branch protection settings, direct updates
to main were rejected.

### Reflection

Branch protection would have reduced the risk of an inconsistent manual deployment similar to the Knight Capital incident. Requiring pull requests creates an explicit review step, while signed commits improve traceability and make impersonation harder. Linear history also makes it easier to audit changes and identify the exact commit introduced into the deployment branch. These controls do not replace automated deployment and rollback mechanisms, but they make unsafe changes harder to push directly.


