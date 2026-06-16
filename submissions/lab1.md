# Lab 1 Submission

## Task 1. SSH Commit Signing and First Signed Commit

### QuickNotes run

#### `GET /health`

```json
{
    "notes": 4,
    "status": "ok"
}
```

#### `GET /notes`

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
        "body": "Start by understanding the entry point ? env vars, signal handling, graceful shutdown.",
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

#### `POST /notes`

```json
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-16T17:01:42.8892587Z"
}
```

#### `GET /notes` after `POST /notes`

```json
[
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point ? env vars, signal handling, graceful shutdown.",
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
        "created_at": "2026-06-16T17:01:42.8892587Z"
    },
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    }
]
```

QuickNotes started successfully on my machine. The application returned four seeded notes on the first `GET /notes`, and after `POST /notes` the total number of notes became five.

### Signed commit verification

```text
commit 5d37ace628815ee1beccedb8fbd2b28f076eb122
Good "git" signature for ilya.syaglovv@gmail.com with ED25519 key SHA256:okgWuKx7Da6Eg2TtpXSeKorFBfWAsRTW9m/cPSEGsOA
Author: Ilia Siaglov <ilya.syaglovv@gmail.com>
Date:   Wed Jun 17 01:02:52 2026 +0800

    docs: add PR template

    Signed-off-by: Ilia Siaglov <ilya.syaglovv@gmail.com>
```

### Verified badge screenshot
![alt text](image.png)


The PR description was filled with the same sections as `.github/pull_request_template.md`. GitHub did not auto-populate it because the PR targets the upstream repository, and GitHub loads templates from the base repository.
### Why signed commits matter

Signed commits provide provenance: reviewers can verify that a commit was really created by the expected author and was not silently forged under someone else's identity. This matters because modern software supply chains depend on trust between maintainers, contributors, and automation. The xz-utils backdoor incident in March 2024 showed how damaging it is when malicious changes blend into a trusted workflow, so stronger authenticity signals such as verified signatures reduce the chance of that trust being abused.

## Task 2. Pull Request Template and First PR

The repository includes a pull request template at `.github/pull_request_template.md`. The lab PR uses this template so the description contains the required Goal, Changes, Testing, and Checklist sections.

### PR evidence
![alt text](image-1.png)


## Task 3. GitHub Community

I starred the course repository and the `simple-container-com/api` project, then followed the professor, TAs, and at least three classmates. Starring repositories helps surface useful projects, signals community interest, and makes good tools easier to rediscover later. Following developers is useful because it exposes ongoing work, helps with collaboration, and builds the habit of staying connected to the engineering community around a project.

## Bonus Task. Branch Protection and Required Signed Commits

### Branch protection screenshot

### Unsigned push rejection

```text
```

### Reflection

If a production branch had required signed commits, pull-request review, and linear history, a risky direct change would have been much harder to push without visibility. In the Knight Capital case, stronger branch controls would likely have forced the deployment through a narrower and more auditable path instead of allowing a catastrophic release process gap. Signed commits would have improved accountability, PR requirements would have added review pressure, and linear history would have made the release trail easier to inspect during incident response. These controls do not guarantee safety, but they substantially reduce the probability of an opaque deployment mistake reaching production unchecked.
