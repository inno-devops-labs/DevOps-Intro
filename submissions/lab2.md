# Lab 2 submission

## Task 1 — Git Object Model + Reflog Recovery 
### Task 1.1 — Git Object Model

#### HEAD commit SHA `git rev-parse HEAD`
bb2822708994e53d35eb64187a7b626b706a8cd2

#### Commit object type `git cat-file -t HEAD`
commit

#### Commit object content `git cat-file -p HEAD`
tree 8e917afa2a6edf00c06d4347d9005a97381f68db
parent a7c9ccbba1c7fee38885b1928bbf7594149e6aee
author DJ Bubu <djbubu28@yahoo.com> 1780638227 +1000
committer DJ Bubu <djbubu28@yahoo.com> 1780638227 +1000
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NI#U0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg6AN3+H9ei+pQNFn2ExZzyej5DK
 C4cG253XDHuoLINDkAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQG5b/ZW9oThZvliBVsdatUXjYA7DASl+c5/8rYbBMccw096fZuOkuVtmEAvm5WDmOc
 emBeraf5ETrmxASzDo0gY=
 -----END SSH SIGNATURE-----

#### Tree object contents `git cat-file -p 8e917afa2a6edf00c06d4347d9005a97381f68db`
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 6db686e340ecdd318fa43375e26254293371942a	labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5	lectures
040000 tree c4d97cb0c02fa9315ffaf57c3f25aab6eec3e0c6	submissions

#### Blob object contents `git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee`
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


### Task 1.2 — Inside .git/

#### High-level structure `ls -la .git/`
drwxr-xr-x. 1 user user  188 Jun  5 17:59 .
drwxr-xr-x. 1 user user   98 Jun  5 15:36 ..
-rw-r--r--. 1 user user   70 Jun  5 16:33 COMMIT_EDITMSG
-rw-r--r--. 1 user user  463 Jun  5 14:30 config
-rw-r--r--. 1 user user   73 Jun  5 08:38 description
-rw-r--r--. 1 user user  563 Jun  5 08:39 FETCH_HEAD
-rw-r--r--. 1 user user   29 Jun  5 16:32 HEAD
drwxr-xr-x. 1 user user  556 Jun  5 08:38 hooks
-rw-r--r--. 1 user user 3451 Jun  5 17:59 index
drwxr-xr-x. 1 user user   14 Jun  5 08:38 info
drwxr-xr-x. 1 user user   16 Jun  5 08:38 logs
drwxr-xr-x. 1 user user  176 Jun  5 16:33 objects
-rw-r--r--. 1 user user   41 Jun  5 17:59 ORIG_HEAD
-rw-r--r--. 1 user user   112 Jun  5 08:38 packed-refs
drwxr-xr-x. 1 user user   32 Jun  5 08:38 refs

#### Current HEAD `cat .git/HEAD`
ref: refs/heads/feature/lab2

#### Local branches `ls .git/refs/heads/`
feature  main

#### Objects directory `ls .git/objects/ | head`
0a
0f
12
14
1a
1d
1f
22
25
27

#### Total loose objects `find .git/objects -type f | wc -l`
find .git/objects -type f | wc -l

#### Interpretation
- `.git/HEAD` points to the currently checked-out branch ref
- `.git/refs/heads/` lists all local branches as plain text files
containing their tip commit SHA
- `.git/objects/` stores all git objects (commits, trees, blobs)
compressed with zlib, organized into subdirectories by the first
2 characters of their SHA hash
- There are X loose objects — these will eventually be packed by
`git gc` into a single `.pack` file for efficiency


### Task 1.3 — Simulate disaster + recover

#### Two commits made `git log --oneline`
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): add Knight Capital reflection
a7c9ccb Added community engagement section
491accc docs(lab1): add GitHub Community section
3d3b2bf docs(lab1): finish submission
9d1d98d docs(lab1): start submission
533c32e docs(lab1): start submission
a7c94d7 docs(lab1): start submission
d9535bf docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
6f044dd (upstream/s26) Replace IPFS with Nix
0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
eaea715 feat: add GitLab CI alternative instructions to lab3
d6b6a03 Update lab2
87810a0 feat: remove old Exam Exemption Policy
1e1c32b feat: update structure
6c27ee7 feat: publish lecs 9 & 10
1826c36 feat: update lab7
3049f08 feat: publish lec8
da8f635 feat: introduce all labs and revised structure
04b174e feat: publish lab and lec #5
67f12f1 feat: publish labs 4&5, revise others
...skipping...
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): add Knight Capital reflection
a7c9ccb Added community engagement section
491accc docs(lab1): add GitHub Community section
3d3b2bf docs(lab1): finish submission
9d1d98d docs(lab1): start submission
533c32e docs(lab1): start submission
a7c94d7 docs(lab1): start submission
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): add Knight Capital reflection
a7c9ccb Added community engagement section
491accc docs(lab1): add GitHub Community section
3d3b2bf docs(lab1): finish submission
9d1d98d docs(lab1): start submission
533c32e docs(lab1): start submission
a7c94d7 docs(lab1): start submission
d9535bf docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
6f044dd (upstream/s26) Replace IPFS with Nix
0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
eaea715 feat: add GitLab CI alternative instructions to lab3
d6b6a03 Update lab2
87810a0 feat: remove old Exam Exemption Policy
1e1c32b feat: update structure
6c27ee7 feat: publish lecs 9 & 10
1826c36 feat: update lab7
3049f08 feat: publish lec8
da8f635 feat: introduce all labs and revised structure
04b174e feat: publish lab and lec #5
67f12f1 feat: publish labs 4&5, revise others
82d1989 feat: publish lab3 and lec3
3f80c83 feat: publish lec2
499f2ba feat: publish lab2
af0da89 feat: update lab1
74a8c27 Publish lab1
f0485c0 Publish lec1
31dd11b Publish README.md

#### Reflog showing full HEAD history `git reflog` 
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to HEAD~2
f9c7587 HEAD@{1}: commit: wip(lab2): more progress
0f1874b HEAD@{2}: commit: wip(lab2): start
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{3}: checkout: moving from feature/lab1 to feature/lab2
bb28227 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: commit: docs(lab1): add Knight Capital reflection
a7c9ccb HEAD@{5}: checkout: moving from main to feature/lab1
eac5ad8 (origin/main, origin/HEAD, main) HEAD@{6}: checkout: moving from feature/lab1 to main
a7c9ccb HEAD@{7}: commit: Added community engagement section
491accc HEAD@{8}: checkout: moving from main to feature/lab1
eac5ad8 (origin/main, origin/HEAD, main) HEAD@{9}: checkout: moving from feature/lab1 to main
491accc HEAD@{10}: commit: docs(lab1): add GitHub Community section
3d3b2bf HEAD@{11}: commit: docs(lab1): finish submission
9d1d98d HEAD@{12}: checkout: moving from main to feature/lab1
eac5ad8 (origin/main, origin/HEAD, main) HEAD@{13}: commit: docs: add PR template
66bbd4d (upstream/main, upstream/HEAD) HEAD@{14}: checkout: moving from feature/lab1 to main
9d1d98d HEAD@{15}: commit: docs(lab1): start submission
533c32e HEAD@{16}: commit: docs(lab1): start submission
a7c94d7 HEAD@{17}: commit: docs(lab1): start submission
d9535bf HEAD@{18}: commit (amend): docs(lab1): align Task 3 GitHub Community engagement with other courses
66bbd4d (upstream/main, upstream/HEAD) HEAD@{19}: checkout: moving from main to feature/lab1
66bbd4d (upstream/main, upstream/HEAD) HEAD@{20}: clone: from github.com:blacktree-lab/DevOps-Intro.git

#### Recovery command `git reset --hard f9c7587`
HEAD is now at f9c7587 wip(lab2): more progress

#### What if git gc had run first?
`git gc` permanently deletes unreferenced objects once the reflog grace period expires (default 30 days, or immediately with `git gc --prune=now`). If garbage collection had run between the bad reset and the recovery attempt, the orphaned commits would have been deleted from `.git/objects/` and their reflog entries pruned — making recovery impossible without an external backup or remote copy.


## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Annotated, signed release tag

####  Tag list `git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'`
v0.1.0-lab2-mackay tag commit

#### Tag verification `git tag -v "v0.1.0-lab2-${USER}"`
object eac5ad8a8f4e84670bacc33ebf4d8c9591221642
type commit
tag v0.1.0-lab2-mackay
tagger DJ Bubu <djbubu28@yahoo.com> 1780652824 +1000

Lab 2 milestone — version control deep dive
Good "git" signature for djbubu28@yahoo.com with ED25519 key SHA256:QARDeDo9ASATwzSKffgwflEQuIS3bgo/m5fIrCCrgpY


### 2.2: Rebase + force-with-lease

#### Capture log before rebase `git fetch origin`
* 30bfe0a (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): task 1 Git Object Model + Reflog Recovery
* f9c7587 wip(lab2): more progress
* 0f1874b wip(lab2): start
* bb28227 (origin/feature/lab1, feature/lab1) docs(lab1): add Knight Capital reflection
* a7c9ccb Added community engagement section
* 491accc docs(lab1): add GitHub Community section
* 3d3b2bf docs(lab1): finish submission
* 9d1d98d docs(lab1): start submission
* 533c32e docs(lab1): start submission
* a7c94d7 docs(lab1): start submission
* d9535bf docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\  
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/
| * 4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
| * 7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
| * 4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
| * 8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
| * 983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
| * 7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
| * aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
| * b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
|/  
* 6f044dd (upstream/s26) Replace IPFS with Nix
* 0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
* eaea715 feat: add GitLab CI alternative instructions to lab3
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10

#### Capture log after rebase `git fetch origin`
* 30bfe0a (HEAD -> feature/lab2, origin/feature/lab2) docs(lab2): task 1 Git Object Model + Reflog Recovery
* f9c7587 wip(lab2): more progress
* 0f1874b wip(lab2): start
* bb28227 (origin/feature/lab1, feature/lab1) docs(lab1): add Knight Capital reflection
* a7c9ccb Added community engagement section
* 491accc docs(lab1): add GitHub Community section
* 3d3b2bf docs(lab1): finish submission
* 9d1d98d docs(lab1): start submission
* 533c32e docs(lab1): start submission
* a7c94d7 docs(lab1): start submission
* d9535bf docs(lab1): align Task 3 GitHub Community engagement with other courses
*   170000c Merge pull request #907 from inno-devops-labs/s26-refactor
|\  
| * d50436c (upstream/s26-refactor) fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
| * 4705a3d fix(.gitignore): stop ignoring submissions/
| * 4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
| * 7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
| * 4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
| * 8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
| * 983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
| * 7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
| * aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
| * b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
|/  
* 6f044dd (upstream/s26) Replace IPFS with Nix
* 0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
* eaea715 feat: add GitLab CI alternative instructions to lab3
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10

#### Merge vs Rebase — when to choose which?
Use **rebase** when working on a personal feature branch to keep a clean, linear history that's easy to review. Use **merge** when integrating long-lived branches or public branches where rewriting history would be disruptive to other contributors. The golden rule: never rebase commits that have already been pushed to a shared branch others are working on.