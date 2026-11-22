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

danielblakeman@Daniels-MacBook-Pro submissions % git commit --no-gpg-sign -s --allow-empty -m "test: unsigned commit (should fail)"
[feature/lab1 f07ff82] test: unsigned commit (should fail)
danielblakeman@Daniels-MacBook-Pro submissions % git push
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 225 bytes | 225.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: error: GH013: Repository rule violations found for refs/heads/feature/lab1.
remote: Review all repository rules at https://github.com/danielblakeman15/DevOps-Intro/rules?ref=refs%2Fheads%2Ffeature%2Flab1
remote: 
remote: - Changes must be made through a pull request.
remote: 
remote: - Commits must have verified signatures.
remote:   Found 1 violation:
remote: 
remote:   f07ff82a7850f4efe13ac2c16a7f47af4a3752c3
remote: 
To https://github.com/danielblakeman15/DevOps-Intro.git
 ! [remote rejected] feature/lab1 -> feature/lab1 (push declined due to repository rule violations)
error: failed to push some refs to 'https://github.com/danielblakeman15/DevOps-Intro.git'
danielblakeman@Daniels-MacBook-Pro submissions % 

![Verification Screenshot](rules_screenshot.png)

Knight Capital would not have missed the 8th server with automated and reviewed deployments.
