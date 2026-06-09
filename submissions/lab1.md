# Lab 1 — Submission

**Student:** Mahmoud Hassan 
**GitHub:** @selysecr332  
**Date:** 00.06.2026

---

## Task 1 — QuickNotes + SSH commit signing

### QuickNotes run (`Invoke-RestMethod` output)

**`GET /health`**

```json
{
    "notes":  5,
    "status":  "ok"
}
```

**`GET /notes`** (before second POST — 5 notes; includes one note from earlier test run)

```json
{
    "value":  [
                  {
                      "id":  1,
                      "title":  "Welcome to QuickNotes",
                      "body":  "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
                      "created_at":  "2026-01-15T10:00:00Z"
                  },
                  {
                      "id":  2,
                      "title":  "Read app/main.go first",
                      "body":  "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
                      "created_at":  "2026-01-15T10:05:00Z"
                  },
                  {
                      "id":  3,
                      "title":  "DevOps mantra",
                      "body":  "If it hurts, do it more often.",
                      "created_at":  "2026-01-15T10:10:00Z"
                  },
                  {
                      "id":  4,
                      "title":  "Endpoint cheat-sheet",
                      "body":  "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
                      "created_at":  "2026-01-15T10:15:00Z"
                  },
                  {
                      "id":  5,
                      "title":  "hello",
                      "body":  "first POST",
                      "created_at":  "2026-06-04T16:56:26.5730911Z"
                  }
              ],
    "Count":  5
}
```

**`POST /notes`**

```json
{
    "id":  6,
    "title":  "hello",
    "body":  "first POST",
    "created_at":  "2026-06-04T16:59:48.7766322Z"
}
```

**`GET /notes`** (after POST — 6 notes)

```json
{
    "value":  [
                  {
                      "id":  1,
                      "title":  "Welcome to QuickNotes",
                      "body":  "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
                      "created_at":  "2026-01-15T10:00:00Z"
                  },
                  {
                      "id":  2,
                      "title":  "Read app/main.go first",
                      "body":  "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
                      "created_at":  "2026-01-15T10:05:00Z"
                  },
                  {
                      "id":  3,
                      "title":  "DevOps mantra",
                      "body":  "If it hurts, do it more often.",
                      "created_at":  "2026-01-15T10:10:00Z"
                  },
                  {
                      "id":  4,
                      "title":  "Endpoint cheat-sheet",
                      "body":  "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
                      "created_at":  "2026-01-15T10:15:00Z"
                  },
                  {
                      "id":  5,
                      "title":  "hello",
                      "body":  "first POST",
                      "created_at":  "2026-06-04T16:56:26.5730911Z"
                  },
                  {
                      "id":  6,
                      "title":  "hello",
                      "body":  "first POST",
                      "created_at":  "2026-06-04T16:59:48.7766322Z"
                  }
              ],
    "Count":  6
}
```

### Signature verification

```text
commit dbbf386a367e0a8f3ff5df48bfa92daa314e8f15
Good "git" signature for mh2325132@gmail.com with ED25519 key SHA256:9OvCsi/f5zN9TWAVj8HsTQLZkJEnKjrkkQZZJi+BYe0
Author: selysecr332 <mh2325132@gmail.com>
Date:   Thu Jun 4 20:19:28 2026 +0300

    docs(lab1): add QuickNotes curl output

    Signed-off-by: selysecr332 <mh2325132@gmail.com>
```

### Verified badge

![Verified badge](screenshots/Lab_1/commit%20fca0ee2.png)

### Why signed commits matter

In March 2024, a malicious backdoor was discovered in xz-utils after an attacker gained maintainer trust over months. Signed commits let reviewers verify that a change really came from a specific key holder, making supply-chain impersonation much harder. They do not replace code review, but they add cryptographic proof of who authored each commit.

---

## Task 2 — PR template + first PR

- PR URL: https://github.com/inno-devops-labs/DevOps-Intro/pull/974

---

## Task 3 — GitHub community

- [ ] Starred course repo + simple-container-com/api
- [ ] Following @Cre-eD, @Naghme98, @pierrepicaud + 3 classmates

### Why stars and follows matter

<!-- your text -->
