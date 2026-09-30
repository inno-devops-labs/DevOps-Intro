# Lab 2 — Version Control Deep Dive

## Task 1 — Git Object Model + Reflog Recovery

### 1.1 Git Object Model

#### HEAD

```text
$ git rev-parse HEAD
ce684e70f326328ca8de7e10d487ae00faf79f36
```

#### Commit object

```text
$ git cat-file -t HEAD
commit

$ git cat-file -p HEAD
tree efd8eaa83a8a7d822ca1fa21b23f5b3a55f6218c
parent 9f41b7deb32343a831b5e47c61533fbc7c0ce67d
author SanyaLikeIT <billboard163rus@gmail.com> 1789107055 +0300
committer SanyaLikeIT <billboard163rus@gmail.com> 1789107055 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAAZcAAAAHc3NoLXJzYQAAAAMBAAEAAAGBAORudC5qaloTbBJaqtw8aL
 lg3d/y6VCWGXjTJeiaBaV1YITBoeK9Q1cdnhdUby+KMq0sc6Yj1sgrbiajtnfRSVpS6+Wg
 0oBuEvoV7zqRJF81wcEtwXDpiU90rabF9To73bB8IR0ZI+q91KGpCZ8u5xbsGd/86jIywq
 RVY6CQWSaRP9XGmGr2FgLsOKzGNZSig1GF3rdOZJGzgyz5FFAkWnXqV/kSWlf8MDjqlLJA
 lDiertYhuuPJAcpODj0Je4rWyPkLiWtzbTLk2NHIkGfLMA3/E11LaDn1pFmwmB9+I7kwf5
 XhOExXzz7/XKAu9nEWhabuA9b77FaV3wt9DdpmJeUltNw3S1O6eognlckbIiEoOGXcEK8Y
 W4X0x26bgKDUzTPAYC/nNg2ErdIDwQCc3TFvQDalZZgTennkuODbUJYGBlGuwqb5hvZAgf
 dwTb1W2MQ0nMp+5EXlYvaMFBiD6QY+E5Q4paWTd0sS4pmlS3mWeWwI+lc1zFEW4YHT7Thc
 +QAAAANnaXQAAAAAAAAABnNoYTUxMgAAAZQAAAAMcnNhLXNoYTItNTEyAAABgAu2CwGGIC
 wLW6R5wWahObcpr7MBkrEeBWSmNT/buqF/fdJbh73toGvkMyL36+yakn78xHwFH+PG0fQq
 8NxYCpsUi6qlrbOYPsEEY1BQ4ZJKvXr86U5/n7aqqV9QDdE1M7PXrlbmcehkoPeWfivAjo
 X+6dCfkzuHg4S7JrMR8C9O42XovpxGIPZeEw4U+S0txD2uKSmKKqoynIGUuZEehQ38m3n5
 KwKIThPe50OybxdtGwpGULFbfjyQdruLEZMzUJgd7qTR/BCQ4p+gsLcDm68cBxMkT/BI9F
 KR9xhPY+uql48sCCuntpZ0Nxr2IavrYBoO9fEQNegBIbItEFXkTD/b1aV3T+Wu6m+AbsJn
 HmcCsLwEODcJt6SxjdaafX3hJ5Dc4lMqSxRgq04Z6CsjQ5baey+IVyzHE0g6vfe9FQGqf1
 L2jHthjNc5A9EqgSRPgmBjGhMRyr5shtwo3kN4vNyYqB6KN3PQpQKGvjl19HGkOGfiE6jy
 0R921fbV7AoruQ==
 -----END SSH SIGNATURE-----

docs: add PR template

Signed-off-by: SanyaLikeIT <billboard163rus@gmail.com>
```

#### Tree object

```text
$ git cat-file -p efd8eaa83a8a7d822ca1fa21b23f5b3a55f6218c
040000 tree bb60f87f1bf33777a9af90426fc18462a110d422	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree f4f047dd07b128eda5f899dfdaaf193f0291eaa2	labs
040000 tree c0ac2d55cf4335df659b347df3d19d0594a06b6c	lectures
```

#### Blob object

```text
$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. So this file must
# ONLY contain:
#   (a) instructor-only paths (refs/), and
#   (b) machine-generated junk that NOBODY should ever commit.
#
# Do NOT add lab DELIVERABLES here (scan reports, SBOMs, go.sum, k8s
# manifests, CI workflows, Dockerfiles, playbooks, dashboards, …). Students
# are told to commit those in their submission PRs — ignoring them upstream
# silently breaks the lab. When in doubt, leave it OUT of this file.

# ── Instructor-only ─────────────────────────────────────────────
# Reference submissions (dry-run worked examples). Never pushed upstream;
# students never see these. This is the one path that is intentionally hidden.
refs/

# ── Machine-generated junk (no one commits these) ───────────────
# Compiled binaries / local runtime state
app/quicknotes
app/data/
/quicknotes
*.exe

# Vagrant runtime state (Lab 5) — the Vagrantfile IS committed; .vagrant/ is not
.vagrant/

# Nix build symlinks (Lab 11) — flake.nix + flake.lock ARE committed; result is not
result
result-*

# Terraform state — MUST never be committed (can contain secrets)
*.tfstate
*.tfstate.backup
.terraform/

# Python virtualenvs / caches
.venv/
__pycache__/
*.pyc

# Editor / IDE
.vscode/
.idea/
*.swp

# OS noise
.DS_Store
Thumbs.db

# Local agent config (not part of the course)
.claude/

# NOTE: deliberately NOT ignored, because students commit them as lab evidence:
#   submissions/labN.md        (lab reports)
#   .github/workflows/*.yml    (Lab 3 CI)
#   Dockerfile, compose.yaml   (Lab 6)
#   ansible/                   (Lab 7)
#   monitoring/                (Lab 8)
#   *.sbom.cdx.json, zap-*.html/json, trivy-*.txt   (Lab 9 scan evidence)
#   flake.nix, flake.lock      (Lab 11)
#   wasm/main.go, spin.toml, go.sum   (Lab 12)
```

HEAD pointed to the tip of `feature/lab2`. The commit references a tree that lists file names and object IDs; the `.gitignore` entry points to the blob containing the file text shown above. This gives the complete chain: `HEAD → commit → tree → blob → file contents`.

### 1.2 Inside .git

```text
$ bash -c 'ls -la .git/'
total 12
drwxrwxrwx 1 alex alex  512 Sep 11 10:33 .
drwxrwxrwx 1 alex alex  512 Sep 11 10:32 ..
-rwxrwxrwx 1 alex alex   20 Sep 11 10:05 COMMIT_EDITMSG
-rwxrwxrwx 1 alex alex  111 Sep 11 10:05 FETCH_HEAD
-rwxrwxrwx 1 alex alex   29 Sep 11 10:23 HEAD
-rwxrwxrwx 1 alex alex   41 Sep 11 10:05 ORIG_HEAD
-rwxrwxrwx 1 alex alex  626 Sep 11 10:23 config
-rwxrwxrwx 1 alex alex   73 Sep 11 07:25 description
drwxrwxrwx 1 alex alex  512 Sep 11 07:25 hooks
-rwxrwxrwx 1 alex alex 3183 Sep 11 10:33 index
drwxrwxrwx 1 alex alex  512 Sep 11 07:25 info
drwxrwxrwx 1 alex alex  512 Sep 11 07:25 logs
drwxrwxrwx 1 alex alex  512 Sep 11 10:05 objects
-rwxrwxrwx 1 alex alex  112 Sep 11 07:25 packed-refs
drwxrwxrwx 1 alex alex  512 Sep 11 09:35 refs
```

```text
$ bash -c 'cat .git/HEAD'
ref: refs/heads/feature/lab2
```

```text
$ bash -c 'ls .git/refs/heads/'
feature
main
```

```text
$ bash -c 'ls .git/objects/ | head'
02
06
07
0a
0c
0e
0f
13
1a
1b
```

```text
$ bash -c 'find .git/objects -type f | wc -l'
69
```

#### Interpretation

`.git/HEAD` contains the symbolic reference `refs/heads/feature/lab2`. The `feature` directory and `main` entry under `.git/refs/heads/` hold local branch references; other references can also be stored in `packed-refs`. The two-character directories under `.git/objects/` store loose objects, while packed objects use pack-related storage. The `find` command returned 69 files, but it counts all files under `.git/objects/`, including any pack-related files, so this is not an exact loose-object count.

### 1.3 Reflog Recovery

#### Two WIP commits

```text
$ git commit -S -s -m 'wip(lab2): start'
[feature/lab2 77d33ea] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md

$ git commit -S -s -am 'wip(lab2): more progress'
[feature/lab2 b5ba601] wip(lab2): more progress
 1 file changed, 1 insertion(+)

$ git log --oneline -5
b5ba601 wip(lab2): more progress
77d33ea wip(lab2): start
ce684e7 docs: add PR template
9f41b7d docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
```

#### Reset and reflog

```text
$ git reset --hard 'HEAD~2'
HEAD is now at ce684e7 docs: add PR template

$ git status
On branch feature/lab2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	task.txt

nothing added to commit but untracked files present (use "git add" to track)

$ git reflog
ce684e7 HEAD@{0}: reset: moving to HEAD~2
b5ba601 HEAD@{1}: commit: wip(lab2): more progress
77d33ea HEAD@{2}: commit: wip(lab2): start
ce684e7 HEAD@{3}: checkout: moving from main to feature/lab2
ce684e7 HEAD@{4}: checkout: moving from feature/lab1 to main
7780851 HEAD@{5}: commit: complete bonus task
d7c6b43 HEAD@{6}: checkout: moving from main to feature/lab1
ce684e7 HEAD@{7}: reset: moving to origin/main
d02a6ec HEAD@{8}: commit: test: unsigned commit (should fail)
ce684e7 HEAD@{9}: reset: moving to ce684e7
221c580 HEAD@{10}: commit: test: unsigned commit (should fail)
ce684e7 HEAD@{11}: reset: moving to ce684e7
7e81e28 HEAD@{12}: checkout: moving from main to main
7e81e28 HEAD@{13}: commit: test: unsigned commit (should fail)
ce684e7 HEAD@{14}: checkout: moving from feature/lab1 to main
d7c6b43 HEAD@{15}: commit: Complete task 3
3414982 HEAD@{16}: commit: docs(lab1): finish submission
0283601 HEAD@{17}: commit: docs(lab1): finish submission
23b61a5 HEAD@{18}: checkout: moving from feature/lab1 to feature/lab1
23b61a5 HEAD@{19}: checkout: moving from main to feature/lab1
ce684e7 HEAD@{20}: commit: docs: add PR template
9f41b7d HEAD@{21}: checkout: moving from feature/lab1 to main
23b61a5 HEAD@{22}: commit: docs: add lab1 screenshots
47ff602 HEAD@{23}: commit (amend): docs(lab1): start submission
073ed0d HEAD@{24}: commit: docs(lab1): start submission
9f41b7d HEAD@{25}: checkout: moving from main to feature/lab1
9f41b7d HEAD@{26}: clone: from https://github.com/SanyaLikeIT/DevOps-Intro.git
```

#### Recovery

```text
$ git reset --hard b5ba601
HEAD is now at b5ba601 wip(lab2): more progress

$ git log --oneline -5
b5ba601 wip(lab2): more progress
77d33ea wip(lab2): start
ce684e7 docs: add PR template
9f41b7d docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls

$ cat submissions/lab2.md
important work
more important work
```

Both WIP commits and both lines of the file were restored.

#### What if `git gc` had run?

After the reset, the WIP commits were no longer reachable from the branch tip, but the reflog still referenced them. A normal `git gc` would usually keep these recent objects because reflog retention and pruning grace periods protect them. Once those references expire and the pruning window passes, or more aggressive cleanup removes the objects, reflog recovery is no longer possible.

## Task 2 — Tag a Release & Rebase

### 2.1 Signed Annotated Tag

```text
$ git tag -a -s v0.1.0-lab2-SanyaLikeIT -m 'Lab 2 milestone — version control deep dive'


$ git push origin v0.1.0-lab2-SanyaLikeIT
To https://github.com/SanyaLikeIT/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-SanyaLikeIT -> v0.1.0-lab2-SanyaLikeIT

$ git tag -l '--format=%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-SanyaLikeIT tag commit

$ git tag -v v0.1.0-lab2-SanyaLikeIT
object ce684e70f326328ca8de7e10d487ae00faf79f36
type commit
tag v0.1.0-lab2-SanyaLikeIT
tagger SanyaLikeIT <billboard163rus@gmail.com> 1789112035 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for billboard163rus@gmail.com with RSA key SHA256:/JBz4CBpgqpsUUo1kNTBLmrQoz8Gz1Dw7fE5+ZATPkA
```

The tag listing shows an annotated tag pointing to a commit, and verification reports a good SSH signature.

### 2.2 Rebase

Branch protection rejected the direct push to `main`, so the main-branch change was merged through PR #1 as `b14c601`. I then rebased the two WIP commits onto `origin/main`.

#### Before rebase

```text
$ git log --oneline --graph --decorate --all -n 20
* b14c601 (origin/main, origin/HEAD, main) docs: upstream moved while you worked (#1)
| * 2bf7774 (origin/lab2/upstream-move, lab2/upstream-move) docs: upstream moved while you worked
|/  
| * b5ba601 (HEAD -> feature/lab2) wip(lab2): more progress
| * 77d33ea wip(lab2): start
|/  
* ce684e7 (tag: v0.1.0-lab2-SanyaLikeIT) docs: add PR template
| * 7780851 (origin/feature/lab1, feature/lab1) complete bonus task
| * d7c6b43 Complete task 3
| * 3414982 docs(lab1): finish submission
| * 0283601 docs(lab1): finish submission
| * 23b61a5 docs: add lab1 screenshots
| * 47ff602 docs(lab1): start submission
|/  
* 9f41b7d (upstream/main, upstream/HEAD) docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/  
```

#### After rebase

```text
$ git log --oneline --graph --decorate --all -n 20
* 05c6123 (HEAD -> feature/lab2) wip(lab2): more progress
* 99c0329 wip(lab2): start
* b14c601 (origin/main, origin/HEAD, main) docs: upstream moved while you worked (#1)
| * 2bf7774 (origin/lab2/upstream-move, lab2/upstream-move) docs: upstream moved while you worked
|/  
* ce684e7 (tag: v0.1.0-lab2-SanyaLikeIT) docs: add PR template
| * 7780851 (origin/feature/lab1, feature/lab1) complete bonus task
| * d7c6b43 Complete task 3
| * 3414982 docs(lab1): finish submission
| * 0283601 docs(lab1): finish submission
| * 23b61a5 docs: add lab1 screenshots
| * 47ff602 docs(lab1): start submission
|/  
* 9f41b7d (upstream/main, upstream/HEAD) docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
| * f0c9243 (upstream/bug/bisect-me) docs(app): mention go test invocation
| * 9fe75cc docs(store): document Count()
| * f285ede refactor(store): simplify nextID restoration in load()
| * cb89bb9 docs(store): comment the load() decode step
| * 0ec87b8 (tag: v0.0.1) chore(app): document versioning scheme (bisect fixture baseline)
|/  
```

The WIP commit IDs changed from `77d33ea` and `b5ba601` to `99c0329` and `05c6123`. Both now follow `b14c601`, with the original changes preserved.

#### Feature branch push

```text
$ git push -u origin feature/lab2
remote: 
remote: Create a pull request for 'feature/lab2' on GitHub by visiting:        
remote:      https://github.com/SanyaLikeIT/DevOps-Intro/pull/new/feature/lab2        
remote: 
branch 'feature/lab2' set up to track 'origin/feature/lab2'.
To https://github.com/SanyaLikeIT/DevOps-Intro.git
 * [new branch]      feature/lab2 -> feature/lab2
```

The remote feature branch did not exist, so it was published with `git push -u origin feature/lab2`.

### 2.3 Merge vs Rebase

I would use rebase on my own feature branch to put my changes on top of the latest main branch and keep the history linear. Merge preserves the actual integration history and is usually safer for shared branches. Rebase changes commit IDs, so rewriting commits that teammates already use can disrupt their work.

## Bonus — Git Bisect

### Build and test environment

```text
$ '/mnt/c/Program Files/Git/bin/sh.exe' -c 'export PATH="/c/Program Files/Go/bin:$PATH"; go version'
go version go1.27.1 windows/amd64
```

The installed Go directory was added to PATH for the test process so Git Bash could find it.

### Bisect run

```text
$ '/mnt/c/Program Files/Git/bin/sh.exe' -c 'export PATH="/c/Program Files/Go/bin:$PATH"; git bisect run sh -c '"'"'cd app && go test ./... && go build ./...'"'"''
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
--- FAIL: TestStore_PersistsAcrossReload (0.02s)
    store_test.go:78: nextID not restored: got 1, want 2
FAIL
FAIL	quicknotes	1.169s
FAIL
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
running 'sh' '-c' 'cd app && go test ./... && go build ./...'
ok  	quicknotes	1.014s
f285ede8611e55ac0a7d01100891c0cc775e0709 is the first bad commit
commit f285ede8611e55ac0a7d01100891c0cc775e0709
Author: Dmitrii Creed <creeed22@gmail.com>
Date:   Fri Jun 5 13:36:56 2026 +0400

    refactor(store): simplify nextID restoration in load()
    
    Signed-off-by: Dmitrii Creed <creeed22@gmail.com>

 app/store.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

### Bisect log

```text
$ git bisect log
git bisect start
# status: waiting for both good and bad commits
# bad: [f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493] docs(app): mention go test invocation
git bisect bad f0c9243b7c80ebb930a1ce7048a1d65b4c2ac493
# status: waiting for good commit(s), bad commit known
# good: [0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7] chore(app): document versioning scheme (bisect fixture baseline)
git bisect good 0ec87b808ae6a257a98ecea4a3c8d38a7f2c5ac7
# bad: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
git bisect bad f285ede8611e55ac0a7d01100891c0cc775e0709
# good: [cb89bb9ee2ee5010b166061447eaca3ae0da2378] docs(store): comment the load() decode step
git bisect good cb89bb9ee2ee5010b166061447eaca3ae0da2378
# first bad commit: [f285ede8611e55ac0a7d01100891c0cc775e0709] refactor(store): simplify nextID restoration in load()
```

### First bad commit

SHA: `f285ede8611e55ac0a7d01100891c0cc775e0709`

Message: `refactor(store): simplify nextID restoration in load()`

```text
$ git show --no-patch '--format=%H %s' f285ede8611e55ac0a7d01100891c0cc775e0709
f285ede8611e55ac0a7d01100891c0cc775e0709 refactor(store): simplify nextID restoration in load()
```

### Why bisect is O(log₂(N))

Git bisect tests a commit roughly halfway between the known good and bad versions. Each good or bad result removes about half of the remaining candidates. This makes the number of checks grow as `log₂(N)` instead of `N`. For about 1,024 commits, it takes roughly 10 checks rather than testing all 1,024.

The bisect log and first bad commit were saved before ending the bisect session and returning to `feature/lab2`.
