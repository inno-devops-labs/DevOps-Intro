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