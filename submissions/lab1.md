# Lab 1 submission

## Task 1

### Task 1.2
```
➜  DevOps-Intro git:(main) curl -s http://localhost:8080/health | python3 -m json.tool
{
    "notes": 4,
    "status": "ok"
}
➜  DevOps-Intro git:(main) curl -s http://localhost:8080/notes  | python3 -m json.tool
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
➜  DevOps-Intro git:(main) curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-09T14:42:24.397493Z"
}
```

### Task 1.4
```
commit dc9aa29c8643a2b7b6fe1ed452632ad6e038a9cd (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for 55945487+Dekart-hub@users.noreply.github.com with ED25519 key SHA256:4mgBS56IPmiiv9CfXkM7q5i3rb7LPWi6N5wlQfYCeVs
Author: Aleksandr <55945487+Dekart-hub@users.noreply.github.com>
Date:   Tue Jun 9 18:07:21 2026 +0300

    docs(lab1): start submission
    
    Signed-off-by: Aleksandr <55945487+Dekart-hub@users.noreply.github.com>
```

### Task 1.5
![Verified commit](verif_screen.png "Screenshot of verified commit")

#### Why signed commits matter:
A signed commit attaches a cryptographic signature proving it was really made by the holder of a specific key, giving you verifiable provenance for every change. This is the class of trust problem the March 2024 xz-utils backdoor exposed.

## Task 3

### GitHub Community:

**Why Stars Matter:**
- Stars help you bookmark interesting projects for later reference
- Star count indicates project popularity and community trust
- Starred repos appear in your GitHub profile, showing your interests
- Stars encourage maintainers and help projects gain visibility

**Why Following Matters:**
- See what other developers are working on
- Discover new projects through their activity
- Build professional connections beyond the classroom
- Stay updated on classmates' work for future collaboration

## Bonus

![Branch rules](verif_screen.png "Screenshot of rules for branches")

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: Review all repository rules at https://github.com/Dekart-hub/DevOps-Intro/rules?ref=refs%2Fheads%2Fmain
remote: 
remote: - Changes must be made through a pull request.
remote: 
remote: - Commits must have verified signatures.
remote:   Found 1 violation:
remote: 
remote:   ff7d6992fd74c478a9629ec052959d3f82ae70bb
remote: 
To github.com:Dekart-hub/DevOps-Intro.git
 ! [remote rejected] main -> main (push declined due to repository rule violations)
error: failed to push some refs to 'github.com:Dekart-hub/DevOps-Intro.git'
```

No need for re-enabling anything because changes in signing made only for this commit. 

### what would Knight Capital's deploy day have looked like with branch protection + required signing on the prod deploy branch?

With branch protection on the prod deploy branch, nothing could reach production without an approved pull request, a green CI run, and linear history - so the release would come from a single reviewed, known-good commit instead of an engineer hand-deploying to 8 servers off a manual checklist where one box silently gets missed. Required signing would make every commit on that branch cryptographically attributable, so you can prove the deployed artifact is exactly the reviewed code and not stale, unverified code lingering on one server.That said, branch protection alone wouldn't have caught Knight's actual trigger - reusing the dormant Power flag and a partial, manual rollout - because that was a deploy-automation failure, not an unsigned-commit problem. 