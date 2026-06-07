# Lab 1 submission

Task 1

```
$ curl -s http://localhost:8080/notes  | python3 -m json.tool
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
$ curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-05T08:19:25.006867363Z"
}

# I add this one gust to show that the last note indeed was added
$ curl -s http://localhost:8080/notes  | python3 -m json.tool
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
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-05T08:19:25.006867363Z"
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
```

```
commit e169036ff55d52b888e438a820bb2aedfccca916 (HEAD -> feature/lab1)
Good "git" signature with ED25519 key SHA256:gTY1GYj4aG1biGVHoqKSQTCfhP9ShQv5lhTuCa2d/h8
Unable to open allowed keys file "/home/long1tail/.ssh/allowed_signers": No such file or directory^M
sig_find_principals: sshsig_find_principal: No such file or directory^M
No principal matched.
Author: Long1TaiL <m.shulaev@innopolis.university>
Date:   Fri Jun 5 12:12:58 2026 +0300

    docs(lab1): start submission
    
    Signed-off-by: Long1TaiL <m.shulaev@innopolis.university>
```

![image](image.png)

Signed commits matter because they cryptographically verify the identity of the author. THerefore, it is much harder to impersonate a trusted maintainer. As z-utils backdoor (March 2024) shows, if attaker can sucsessfully ippersonate and get acsess to some utisl sorce code, it can compromise the whole internet onfratructure.

Task 2

This task does not require any notes here, but I'll ad this text to fit the acceptance criteria

Task 3

GitHub Social Features

In open source, starring repositories plays a key role in helping projects get discovered and validated—boosting their visibility, signaling trustworthiness, and drawing in new contributors. At the same time, following developers supports your professional development and keeps your team on the same page, as it provides ongoing insights into industry trends, fresh coding approaches, and the latest work of your colleagues.

Bonus task

