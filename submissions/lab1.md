# Lab 1 submission
## Task 1 — SSH Commit Signing & First Signed Commit
### Check quick notes API health endpoint
`curl -s http://localhost:8080/health | python3 -m json.tool`

```json
// OutPut
{
    "notes": 4,
    "status": "ok"
}
//
```

### Retrieve (GET) seed note via endpoint (app/data.json)
`curl -s http://localhost:8080/notes  | python3 -m json.tool`
```json
// Output
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
//
```

### Add first note using POST action
`
curl -s -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"hello","body":"first POST"}' | python3 -m json.tool
`
```json
// Output
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-11-02T10:55:26.431771725Z"
}
//
```

### Further retrieve to see all notes or explicitly the first note where id=5
```json
// Fetch all seed notes
curl -s http://localhost:8080/notes  | python3 -m json.tool   

// Fetch the newest note where id=5
curl -s http://localhost:8080/notes/5  | python3 -m json.tool

//OutPut
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
        "created_at": "2026-11-02T10:55:26.431771725Z"
    }
]

```

### Good Signature - Requires AllowedSignersFile Configuration
```bash
# Create ~/.config/git/allowed_signers
mkdir -p ~/.config/git
touch ~/.config/git/allowed_signers

# Config Allowed signers globally
git config --global gpg.ssh.allowedSignersFile "~/.config/git/allowed_signers"

# Add pub signing key to allowed_signers
your-git-email ssh-ed25519-----rest of your public key----HDDD28SSDS


# Actual Good Signature Output
git log --show-signature -1
commit 6a75b4e749f80f925b294c9e8c6cd1716f357397 (HEAD -> feature/lab1)
Good "git" signature for adeboye.francis@icloud.com with ED25519 key SHA256:6vWK+uDtgqZF9lp/MiJd7/yyhIxNejnO8xr9nN5icQk
Author: Francis Adeboye <adeboye.francis@icloud.com>
Date:   Mon Nov 2 11:48:56 2026 +0000

    docs(lab1): start submission
    
    Signed-off-by: Francis Adeboye <adeboye.francis@icloud.com>

# Verification badge to be displayed after PR launched
```

### Rationale for Signed Commits

- **Security:** Signed commits provide an additional layer of identity verification by cryptographically validating the author of each commit. This helps ensure that only authorized contributors can make changes to the codebase, reducing the risk of unauthorized modifications, compromised accounts, or malicious actors introducing backdoors with reference to xz-utils incident of "Lazy Maintainer and Helpful Stranger". It reinforces a shift-left security approach by embedding trust and verification throughout the DevOps lifecycle.

- **Traceability:** Each signed commit is linked to a verified cryptographic identity, creating a reliable audit trail. This improves accountability by helping teams determine **who** made a change, **what** was changed, and **when** it occurred. During investigations, incident response, or compliance audits, signed commits provide greater confidence in the integrity and origin of code changes.


## Task 2 — Pull Request Template & First PR

The PR template has been added to `.github/pull_request_template.md` on the main branch of project


### GitHub Community

Starring Open source project makes a positive impact in the github community both to owner/contributor professional growths and create an innovative movement to inspire creative expertise

### Actions completed:
-  Starred the course repository (inno-devops-labs/DevOps-Intro)
-  Starred simple-container-com/api project
-  Following professor: @Cre-eD
