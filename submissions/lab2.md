# Lab 2 Submission — Version Control Deep Dive

## Task 1 — Git Object Model and Reflog Recovery

This lab explores Git internals, reflog recovery, signed tags, rebase workflow, and bisect debugging.

### 1.1 Git object model: HEAD to tree to blob

Command:

    git rev-parse HEAD

Output:

    66bbd4db9228bc9a4cab7439746b993749c026ab

Command:

    git cat-file -t HEAD

Output:

    commit

Command:

    git cat-file -p HEAD

Output summary:

    tree 20bda2b2625085720751a3e794f82e5625a409b3
    parent 170000c9d1b5e90a37b6f1a9b826552d53051773
    author Dmitrii Creed <creeed22@gmail.com>
    commit message: docs(lab1): align Task 3 GitHub Community engagement with other courses

Command:

    git cat-file -p 20bda2b2625085720751a3e794f82e5625a409b3

Output:

    100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
    100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
    040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
    040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
    040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

Command:

    git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e | head -40

Output summary:

    The blob contains the beginning of README.md, including the course title, course roadmap, and the QuickNotes project description.

Interpretation:

    HEAD points to a commit object. The commit object points to a tree object. The tree object stores directory entries, file modes, object types, object SHAs, and file names. The README.md entry points to a blob object, and the blob contains the actual file contents.

### 1.2 Inspecting the `.git/` directory

Command:

    ls -la .git/
    cat .git/HEAD
    ls .git/refs/heads/
    ls .git/objects/ | head
    find .git/objects -type f | wc -l

Important output:

    HEAD: ref: refs/heads/feature/lab2
    Branches: feature and main
    Loose object count: 16

Interpretation:

    The `.git/` directory stores the repository metadata and history. The HEAD file points to the current branch reference, which is `refs/heads/feature/lab2`. The refs directory stores branch names, while the objects directory stores Git objects such as commits, trees, and blobs. The loose object count shows how many unpacked Git objects are currently stored in `.git/objects`.

### 1.3 Reflog recovery after reset hard

Temporary commits were created for the recovery exercise:

    0884c7f wip(lab2): start reflog recovery section
    709ae8a wip(lab2): add more reflog recovery notes

A destructive reset was simulated with:

    git reset --hard HEAD~2

Output:

    HEAD is now at 32b935a docs(lab2): document git object model

After the reset, `git log --oneline -5` no longer showed the two WIP commits. However, `git reflog -5` still showed them:

    32b935a HEAD@{0}: reset: moving to HEAD~2
    709ae8a HEAD@{1}: commit: wip(lab2): add more reflog recovery notes
    0884c7f HEAD@{2}: commit: wip(lab2): start reflog recovery section
    32b935a HEAD@{3}: commit: docs(lab2): document git object model
    66bbd4d HEAD@{4}: checkout: moving from main to feature/lab2

The latest lost commit was recovered with:

    git reset --hard 709ae8a

Output:

    HEAD is now at 709ae8a wip(lab2): add more reflog recovery notes

After recovery, the branch history showed the recovered commits again:

    709ae8a wip(lab2): add more reflog recovery notes
    0884c7f wip(lab2): start reflog recovery section
    32b935a docs(lab2): document git object model

If `git gc` had aggressively pruned unreachable objects before recovery, the lost commits might no longer have been recoverable. In normal Git usage, reflog retention gives a recovery window, but relying on it is still risky. The safe practice is to commit or stash important work before destructive commands like `git reset --hard`.
---

## Task 2 — Signed Tag and Rebase

### 2.1 Annotated signed release tag

Tag created:

    v0.1.0-lab2-tivdzualubem

Command:

    git tag -a -s "v0.1.0-lab2-tivdzualubem" -m "Lab 2 milestone — version control deep dive"

Verification command:

    git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
    git tag -v "v0.1.0-lab2-tivdzualubem"

Output:

    v0.1.0-lab2-tivdzualubem tag commit
    object ba1ae62a773bf3b19048b0425ebff3833ede7abb
    type commit
    tag v0.1.0-lab2-tivdzualubem
    tagger Tivdzualubem <tivdzualubem@gmail.com>

    Lab 2 milestone — version control deep dive
    Good "git" signature for tivdzualubem@gmail.com

Interpretation:

    The tag is annotated because its object type is `tag`, and it points to a commit. The tag is signed because `git tag -v` reports a good SSH signature.
### 2.2 Rebase onto a moved base

Before rebase, the branch history was:

    * cce0712 (HEAD -> feature/lab2) docs(lab2): document signed tag
    * a6f4f1d (tag: v0.1.0-lab2-tivdzualubem) docs(lab2): document reflog recovery
    * 709ae8a wip(lab2): add more reflog recovery notes
    * 0884c7f wip(lab2): start reflog recovery section
    * 32b935a docs(lab2): document git object model
    * 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses

To simulate the base branch moving while Lab 2 work was in progress, I created a temporary simulated base from `upstream/main`:

    git switch -c lab2-sim-main upstream/main
    git commit -S -s --allow-empty -m "docs: upstream moved while lab2 worked"

The simulated moved base commit was:

    37c76a0 docs: upstream moved while lab2 worked

Then I rebased the Lab 2 branch onto that moved base:

    git switch feature/lab2
    git rebase lab2-sim-main

After rebase, the branch history became:

    * 6007f0d (HEAD -> feature/lab2) docs(lab2): document signed tag
    * c8af630 docs(lab2): document reflog recovery
    * d675f60 wip(lab2): add more reflog recovery notes
    * cde0d69 wip(lab2): start reflog recovery section
    * 7ba0f06 docs(lab2): document git object model
    * 37c76a0 (lab2-sim-main) docs: upstream moved while lab2 worked
    * 66bbd4d (upstream/main, upstream/HEAD) docs(lab1): align Task 3 GitHub Community engagement with other courses

Interpretation:

    Rebase replayed the Lab 2 commits on top of the moved base commit. This produced new commit SHAs because rebase rewrites commits. I would choose rebase for a short-lived feature branch when I want a clean linear history before opening a PR. I would choose merge when preserving the exact branch topology matters or when working on a shared branch that other people may already depend on.

---

## Bonus Task — Bisect a Real Bug

**Bisect setup:** branch `bisect-quickn` from `upstream/bug/bisect-me`

**Git bisect log:**
\`\`\`
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
**Offending commit:**

SHA: f285ede8611e55ac0a7d01100891c0cc775e0709  
Message: refactor(store): simplify nextID restoration in load()

**Explanation:**  
Git bisect performs a binary search across commits. At each step, it checks out the midpoint between known good and bad commits, tests/builds, and narrows the search space. This finds the first bad commit efficiently in log₂(N) steps, here identifying the commit that breaks `TestStore_PersistsAcrossReload`.
