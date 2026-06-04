# Lab 1 submission

## Task 1

curl -s http://localhost:8080/health | python3 -m json.tool 

{ 
   "notes": 4, 
   "status": "ok" 
} 

curl -s http://localhost:8080/notes  | python3 -m json.tool 

[ 
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
       "id": 1, 
       "title": "Welcome to QuickNotes", 
       "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.", 
       "created_at": "2026-01-15T10:00:00Z" 
   } 
] 

curl -s -X POST http://localhost:8080/notes \ 
 -H 'Content-Type: application/json' \ 
 -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool 

{ 
   "id": 5, 
   "title": "hello", 
   "body": "first POST", 
   "created_at": "2026-06-04T09:09:47.915521351Z" 
}

Good "git" signature with ED25519 key SHA256:C0WvWARzsC87AMQBs2ZmgKYf1rOjvTkKcrg6fro2VGw

<img width="1427" height="212" alt="image" src="https://github.com/user-attachments/assets/4eb59b34-d43e-4745-aed1-33404dc8abfb" />

Why signed commits matter

In March 2024, the xz-utils backdoor attack proved that commit authorship can be easily faked. Anyone can put someone else's name and email in Git config. Signed commits solve this by cryptographically proving that a commit actually came from the key owner. Without signing, you can never be sure if code really came from a trusted developer or from an attacker who compromised their account. That's why GitHub requires signed commits.

## Task 2

PR template added to .github/pull_request_template.md on main branch. PR opened from feature/lab1 to course main with template sections filled.

## Task 3

Stars help bookmark interesting projects, show community trust, and encourage maintainers. Following developers lets me see their activity, discover new projects, and stay connected with classmates and mentors beyond the classroom.

## Bonus

Branch protection enabled on main: require signed commits, require PR before merging, require linear history.

<img width="884" height="1010" alt="image" src="https://github.com/user-attachments/assets/0897b791-57bf-4bfa-9a34-8b2a95167bf1" />

Unsigned commit push result:

remote: Bypassed rule violations for refs/heads/main:
remote: 
remote: - Commits must have verified signatures.
remote:   Found 1 violation:
remote:   cbb252da3df8707bd6b3fba6a41556cc31871282
remote: 
remote: - Changes must be made through a pull request.

Knight Capital lost $440M in 45 minutes because a manual deploy missed one server running dead code. With branch protection and required signed commits on the prod deploy branch, every push would have been cryptographically verified and forced through a pull request. The stale Power Peg code could not have been pushed without review, and the unsigned deploy would have been blocked entirely. Automated checks would have caught the mismatch between servers before market open. A single missing server in a manual deploy checklist destroyed a 1,000-person company — branch protection makes such oversights technically impossible.
