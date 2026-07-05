# Lab 1 submission

## Task 1

### App Curl Results

```bash
$ curl http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl http://localhost:8080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
$ curl -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"first","body":"hello"}'
{"id":5,"title":"first","body":"hello","created_at":"2026-06-06T14:25:14.429665522Z"}
```

### Local Sign Verification

```bash
$ git log --show-signature -1
commit f0798f5bc16e4bb8b99872479236c8a6449b28a2 (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for rybenko.urii@gmail.com with RSA key SHA256:5+QHMVYRnfNneCLqbLVqF/WRPbn4KvwSiMxoL/s2UkE
Author: yury <rybenko.urii@gmail.com>
Date:   Sat Jun 6 16:34:26 2026 +0300

    docs(lab1): start submission

    Signed-off-by: yury <rybenko.urii@gmail.com>
```

### GitHub Sign Verification

![alt text](image.png)

### Git Sign Explanation

Signed commits matter because Git names and emails are easy to fake, while a signature gives reviewers cryptographic evidence that the commit was made by the holder of a trusted key. As [Lecture 1, Slide 16](../lectures/lec1.md#-slide-16---signed-commits--the-supply-chain) explains, the xz-utils incident in March 2024 showed how dangerous weak provenance can be: an attacker spent years gaining trust and nearly shipped a backdoor into a critical Linux dependency. Verified commits do not solve every supply-chain problem, but they make impersonation and suspicious history much easier to detect during review.

## Task 2

https://github.com/Ten-Do/DevOps-Intro/blob/main/.github/pull_request_template.md

![alt text](image-2.png)

## Task 3

**Why starring repositories matters in open source:** Starring a repository not only bookmarks it for your own reference but also signals community trust and interest, helping maintainers gain visibility and attract contributors.

**How following developers helps in team projects and professional growth:** Following developers keeps you updated on their activity and project progress, which strengthens collaboration in team settings while exposing you to new tools and practices that accelerate your professional development.

## Task 4

![alt text](image-1.png)

```bash
$ git switch main
# disable signing temporarily
git commit -S=false -s --allow-empty -m "test: unsigned commit (should fail)"
git push origin main
# expected: remote rejects with "must be signed" error
Switched to branch 'main'
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)
error: Couldn't load public key =false: No such file or directory?

fatal: failed to write commit object
To github.com:Ten-Do/DevOps-Intro.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'github.com:Ten-Do/DevOps-Intro.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

With branch protection and required signing on the prod branch, Knight Capital's flawed deployment would have been blocked before the merge. The missing server configuration and the dormant "Power Peg" code would have been caught during mandatory peer review and status checks. As a result, the catastrophic failure would have been avoided.
