# Lab 1 submission

```powershell
PS C:\Users\danielpancake> curl -s http://localhost:8080/health | py -m json.tool
{
    "notes": 4,
    "status": "ok"
}

PS C:\Users\danielpancake> curl -s http://localhost:8080/notes  | py -m json.tool
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
        "body": "Start by understanding the entry point \u0432\u0402\u201d env vars, signal handling, graceful shutdown.",
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

PS C:\Users\danielpancake> curl -s -X POST http://localhost:8080/notes -H 'Content-Type: application/json' -d '{"title":"hello","body":"first POST"}' | py -m json.tool
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-15T09:55:15.2678968Z"
}
```

```powershell
PS D:\Desktop\DevOps-Intro> git log --show-signature -1

commit e3d2855371da8a8f0d6613c0140b20dac93cb803 (HEAD -> feature/lab1)
Good "git" signature for 45727078+danielpancake@users.noreply.github.com with ED25519 key SHA256:9X3YQHiqrWoDjoaRwFmJ5YC04AAtZX8GDBNeS3atwEk
Author: danielpancake <45727078+danielpancake@users.noreply.github.com>
Date:   Mon Jun 15 15:02:53 2026 +0500

    docs(lab1): start submission

    Signed-off-by: danielpancake <45727078+danielpancake@users.noreply.github.com>
```

![Showing verified badge](image/lab1/1781518238214.png)
