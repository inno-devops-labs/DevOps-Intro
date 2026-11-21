# Lab 1 submission

![Verified commit badge on GitHub PR](./danielblakmean15_github_verified_screenshot.png)

danielblakeman@Daniels-MacBook-Pro submissions % curl -s http://localhost:8080/health | python3 -m json.tool
{
    "notes": 5,
    "status": "ok"
}
danielblakeman@Daniels-MacBook-Pro submissions % curl -s http://localhost:8080/notes  | python3 -m json.tool
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
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-11-21T14:03:33.167919Z"
    }
]
danielblakeman@Daniels-MacBook-Pro submissions % git log --show-signature -1
commit 55fbab9934ebd91c79de1781b3d6e4fc5699d825 (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for danielblakeman15@gmail.com with ED25519 key SHA256:cW9yQ85NZVpgKIVumY9t29j+HgXyEYncdcHEVmj+V4Q
Author: Daniel Blakeman <danielblakeman15@gmail.com>
Date:   Sat Nov 21 09:18:17 2026 -0500

    docs(lab1): start submission

    Signed-off-by: Daniel Blakeman <danielblakeman15@gmail.com>

Signed commits matter because "Anyone can put any name and email in git config - your commit history is unauthenticated by default".

A signed commit shows who actually made the commit. 
