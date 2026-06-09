# Lab 1 submission

## Task 1 — SSH signing + QuickNotes

### QuickNotes checks

```json
{
    "notes": 4,
    "status": "ok"
}
```

```json
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
        "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
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

```json
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-09T06:18:34.102767Z"
}
```

```json
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
        "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
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
        "created_at": "2026-06-09T06:18:34.102767Z"
    }
]
```

### Why signed commits matter

Signed commits let reviewers verify that a change really came from the claimed author and was not altered in transit. The xz-utils compromise in March 2024 showed how a hidden backdoor can travel through trusted-looking code paths, so signing adds one more layer of trust and accountability. In a team workflow, that makes it much harder to sneak in tampered history unnoticed.

### Local signature verification

```text
commit 036fdc2e020f08d657f678fcd76a8eda8f6de31a
Good "git" signature for irina.bychkova06@mail.ru with ED25519 key SHA256:0QziAHQZeFYu2R3UOly0My2Bl/aGmRK46bdyePgznWM
Author: Irina <irina.bychkova06@mail.ru>
Date:   Tue Jun 9 09:22:52 2026 +0300

    docs(lab1): start submission

    Signed-off-by: Irina <irina.bychkova06@mail.ru>
```

Screenshot of the Verified badge: add after pushing the signed commit to GitHub.

## Task 2 — Pull request template

The pull request template was added on the `main` branch at `.github/pull_request_template.md`. It contains sections for the goal, changes, testing, and a checklist for title quality, signed commits, and the lab submission file.

After opening the PR from `feature/lab1` to the course repository's `main`, the PR description should auto-populate with the template. Screenshot or PR URL: add after opening the PR.

## Task 3 — GitHub Community

Starring repositories matters because stars help bookmark useful projects, signal community interest, and give maintainers visibility. Following developers helps in team projects because it makes classmates' and instructors' work easier to discover, and it supports professional growth through exposure to real engineering activity.

Community actions completed:

- [ ] Starred `inno-devops-labs/DevOps-Intro`
- [ ] Starred `simple-container-com/api`
- [ ] Followed `@Cre-eD`
- [ ] Followed `@Naghme98`
- [ ] Followed `@pierrepicaud`
- [ ] Followed at least 3 classmates
