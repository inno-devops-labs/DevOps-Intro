# Lab 1 submission

## Task 1 - SSH Commit Signing and QuickNotes

### Working app

**GET /health**

```json
{
    "notes": 4,
    "status": "ok"
}
```

**GET /notes (before POST)**

```json
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
        "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
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
```

**POST /notes**

```json
{
    "id": 5,
    "title": "hello",
    "body": "first POST",
    "created_at": "2026-06-09T11:24:09.659449Z"
}
```

**GET /notes (after POST)**

```json
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
        "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
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
        "created_at": "2026-06-09T11:24:09.659449Z"
    }
]
```

### Good signature

```
commit 3cbfeb2a2a10b2cdb08390901d1c2ea3bdc74c3d
Good "git" signature for hidancloud@yandex.ru with ED25519 key SHA256:0suWfmEHZ/Xt+yrRNKc2HZQbjzw33ZGHOnxmXKllv54
Author: Arseny Pinigin <hidancloud@yandex.ru>
Date:   Tue Jun 9 14:25:02 2026 +0300

    docs(lab1): start submission

    Signed-off-by: Arseny Pinigin <hidancloud@yandex.ru>
```

### Verified badge

![screenshot with Verified badge](verified_badge.png)

### Why signed commits matter

Git commit metadata (name and email) is not authenticated by default — anyone can set any author in `git config`. A signed commit is a cryptographic proof that the commit was made by the holder of a specific SSH key. In March 2024, an attacker maintained the xz-utils project for two years and nearly slipped a backdoor into Linux SSH daemons through a supply-chain attack. Signed commits and verified authorship make it harder for attackers to land malicious changes while impersonating a trusted contributor.

## Task 2 - Pull Request Template and First PR

Added `.github/pull_request_template.md` to fork `main` (signed commit `8e61358`). The template includes Goal, Changes, Testing, and Checklist sections.

**PRs will be opened at the end** — after all lab tasks (including the bonus) are complete on `feature/lab1`:

1. Fork PR: `feature/lab1` → `Hidancloud/DevOps-Intro` `main` (template should auto-populate from fork `main`)
2. Course PR: `Hidancloud/DevOps-Intro` `main` → `inno-devops-labs/DevOps-Intro` `main` (template pasted manually, since the course repo does not have our template on `main`)

Prepared PR descriptions are ready in `lab1_reproduce.md` sections 8 and 9.

## Task 3 - GitHub Community

Completed on GitHub:

1. Starred the course repository (`inno-devops-labs/DevOps-Intro`)
2. Starred [simple-container-com/api](https://github.com/simple-container-com/api)
3. Followed the professor ([@Cre-eD](https://github.com/Cre-eD)) and TAs ([@Naghme98](https://github.com/Naghme98), [@pierrepicaud](https://github.com/pierrepicaud))
4. Followed at least 3 classmates from the course

Starring repositories helps bookmark useful projects for later and signals community interest to maintainers, which supports discovery and trust in open source. Following developers (professor, TAs, and classmates) makes it easier to see what others are building, stay updated on their work, and build professional connections for future team projects.

## Bonus Task - Branch Protection and Required Signed Commits

### Branch protection rule

Created ruleset **main protection** on fork `main` with:

- Require a pull request before merging
- Require signed commits
- Require linear history

![branch protection ruleset](branch-ruleset-1.png)

![branch protection ruleset details](branch-ruleset-2.png)

### Unsigned push rejection

```
$ git push origin main
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: Review all repository rules at https://github.com/Hidancloud/DevOps-Intro/rules?ref=refs%2Fheads%2Fmain
remote:
remote: - Changes must be made through a pull request.
remote:
remote: - Commits must have verified signatures.
remote:   Found 1 violation:
remote:
remote:   d085da79b2f802fa568fde937fcdaa24d2323765
remote:
To github.com:Hidancloud/DevOps-Intro.git
 ! [remote rejected] main -> main (push declined due to repository rule violations)
error: failed to push some refs to 'github.com:Hidancloud/DevOps-Intro.git'
```

### Reflection

Knight Capital's 2012 incident happened partly because a manual deploy missed one of eight production servers, leaving stale trading code running for 45 minutes and causing a $440M loss. With branch protection and required signed commits on a production deploy branch, every change would have to go through a reviewed PR, and only cryptographically verified commits could merge — reducing the chance of unaudited or impersonated code reaching production. Linear history would also make it clearer exactly what was deployed and when, instead of relying on ad-hoc manual checklists across multiple servers.
