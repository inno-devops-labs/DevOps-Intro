# Lab 1 — DevOps Foundations


## Task 1 — SSH Commit Signing & Running QuickNotes

What have I done?
### Running QuickNotes

`GET /health`:

{
    "notes": 4,
    "status": "ok"
}

`GET /notes` — 4 seed notes:

[
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
    }
]


`POST /notes` — created note:

{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-03T03:39:14.041723Z"
}

After the POST, `GET /notes` returns 5 notes, confirming the write persisted.

### Signed commit verification

`git log --show-signature -1`:

Good "git" signature for hydrogenim@yandex.ru with ED25519 key SHA256:A4DMi3JBqhY4gzOwwFEp42EaHJwR+5cF6LIWpVPtyYs

Verified badge on GitHub:

![Verified badge](verified_badge.png)

### Why signed commits matter

Signed commits cryptographically bind each commit to a verified identity (proving the code truly came from that person). This provenance is core to supply-chain security: the March 2024 xz-utils incident showed how attackers exploit trust in the contribution pipeline. To be honest, signing alone would not have stopped them, because the malicious maintainer was trusted and much of the malicious code was in the release tarballs(differed from the git source). And that is the lesson: if everyone had built from the git repository (with verified commits), those malicious build-script changes simply would not have appeared.

---

## Task 2 — Pull Request Template & First PR

What have I done?

- Added `.github/pull_request_template.md` to `main`.
- Opened a PR `feature/lab1` → upstream `main`; the description auto-populated from the template.



![PR template auto-populated](pr-template.png)

---

## Task 3 — GitHub Community

What have I done?
- Starred the course repo and `simple-container-com/api`.
- Followed the professor (@Cre-eD), TAs (@Naghme98, @pierrepicaud), and 3 classmates.

Stars allow bookmarking projects(to probably use them later) and boost visibility and credibility in the community. Following maintainers shows me what others are working on, which makes future collaboration easier(not to forget that those people exist)

---

## Bonus Task — Branch Protection:

![Branch protection rules](branch-protection.png)

Rejected unsigned push:
```
<строка remote: error: ...>
```

<3–4 предложения рефлексии про Knight Capital>