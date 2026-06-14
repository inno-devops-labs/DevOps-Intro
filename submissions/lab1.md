# Lab 1 submission


TASK 1 - QUICKNOTES 

 * [new tag]         v0.0.1        -> v0.0.1
i@is-MacBook-Air DevOps-Intro % cd app/
i@is-MacBook-Air app % go run .
2026/06/14 12:27:46 quicknotes listening on :8080 (notes loaded: 4)

                            CURLS OUTPUTS
i@is-MacBook-Air DevOps-Intro % curl -s http://localhost:8080/health
curl -s http://localhost:8080/notes
curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}'
{"notes":6,"status":"ok"}
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"hello","body":"first POST","created_at":"2026-06-14T11:29:02.00957Z"},{"id":6,"title":"hello","body":"first POST","created_at":"2026-06-14T11:59:20.238849Z"}]
{"id":7,"title":"hello","body":"first POST","created_at":"2026-06-14T13:07:50.09238Z"}
i@is-MacBook-Air DevOps-Intro % 

                                                GIT SIGNATURE PROOF
i@is-MacBook-Air DevOps-Intro % git log --show-signature -1
commit 73fa34a86bfe066e2bbb8d669663c5ea3a2ae8a3 (HEAD -> feature/lab1, origin/feature/lab1)
Good "git" signature for daliquido@gmail.com with ED25519 key SHA256:QJszduGF5LHvHvUEWqVLzBcYWy1zHw/7iiKUotUdXSM
Author: Ayomide <daliquido@gmail.com>
Date:   Sun Jun 14 13:48:19 2026 +0100

    docs(lab1): add GitHub community section
    
    Signed-off-by: Ayomide <daliquido@gmail.com>
i@is-MacBook-Air DevOps-Intro % 
                                            EXPLANATION
Signed commits ensure the authenticity and integrity of code changes by cryptographically linking commits to a verified developer identity.
This helps prevent supply-chain attacks like the xz-utils incident (March 2024), where malicious code was introduced through compromised contributions.
With signed commits, maintainers can trust that commits actually come from the claimed author and have not been tampered with.

TASK 2 - TEMPLATES

TEMPLATES EXISTS

i@is-MacBook-Air DevOps-Intro % ls .github/pull_request_template.md
.github/pull_request_template.md
i@is-MacBook-Air DevOps-Intro % 
TASK 3
COURSE REPO STARRED
SIMPLE CONTAINER ALLOW

EVERYONE FOLLOWED

## GitHub Community
Starring repositories helps developers bookmark useful projects and signals interest and trust in open-source work. It also increases visibility for maintainers and contributes to project growth.


Following developers helps me track activity, discover new tools, and stay connected with peers for collaboration in future projects and team environments.
Following developers helps me track activity, discover new tools, and stay connected with peers for collaboration in future projects and team environments.

BONUS

REJECTION
remote: GH013: Repository rule violations found
remote: - Changes must be made through a pull request.
remote: - Commits must have verified signatures.

REFLECTION
Branch protection would have prevented unsafe or unreviewed changes from reaching production. Signed commits ensure authenticity of changes and prevent unauthorized or tampered code. Together, these controls enforce accountability and reduce risk in deployment pipelines. In a system like Knight Capital, this would have prevented direct faulty deployments.

main

