# Lab 1 submission

## Working app

`id` of new note is 6, not 5, because I didn't save the output first time, so I deleted note with `id` = 5 and created note again.

```
tatyana@Tatyanas-MacBook-Air DevOps-Intro % curl -s http://localhost:8080/health | python3 -m json.tool
{
    "notes": 4,
    "status": "ok"
}
tatyana@Tatyanas-MacBook-Air DevOps-Intro % curl -s http://localhost:8080/notes  | python3 -m json.tool
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
tatyana@Tatyanas-MacBook-Air DevOps-Intro % curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
{
    "id": 6,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-08T18:55:20.809213Z"
}
tatyana@Tatyanas-MacBook-Air DevOps-Intro % curl -s http://localhost:8080/notes  | python3 -m json.tool                               
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
    },
    {
        "id": 6,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-08T18:55:20.809213Z"
    }
]
```

## Good signature

```
tatyana@Tatyanas-MacBook-Air DevOps-Intro % git log --show-signature -1
commit 9f5505671af16c37cea05a4e928945741791031f (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for limefox413@gmail.com with ED25519 key SHA256:uILBmFloXYwLzB7ZEV76znUjoz28KKEF7OZWNJr7Jio
Author: Tatyana Shmykova <limefox413@gmail.com>
Date:   Mon Jun 8 21:49:08 2026 +0300

    docs(lab1): start submission
    
    Signed-off-by: Tatyana Shmykova <limefox413@gmail.com>
```

## Verified badge

![screenshot with Verified badge](image.png)

Signed commits matter because they prove that a commit was created with a trusted private key and was not changed after signing. In the xz-utils case in March 2024, malicious code was added through a trusted open source project, so strong identity checks would help reviewers see who made sensitive changes. Signing does not make code safe by itself, but it adds an important layer of trust and accountability.

## GitHub Community

Starring repositories matters in open source because it helps people save useful projects, shows interest in the project, and gives maintainers more visibility. Following developers helps in team projects and professional growth because you can see their work, learn from their activity, and stay connected with classmates or future collaborators.