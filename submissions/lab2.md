# Lab 2 Submission

## Task 1.1 — Git Object Model

### HEAD Commit

```text
24cef066f3ae1e776290bf835a6e393cee99e4b8
```

### Object Type

```text
commit
```

### Commit Contents

```text
tree 01e9b2e7a6d5fccf3268951664c73dd6b4357db6
parent 66bbd4db9228bc9a4cab7439746b993749c026ab
author Muhammadjon Aslonov <muhammadjonaslonov4@gmail.com>
committer Muhammadjon Aslonov <muhammadjonaslonov4@gmail.com>
```

### Tree Contents

```text
040000 tree d0f15a494317a8a43f617b9d4784429b9c5167ab .github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e README.md
```

### Blob Chain

```text
Tree: d0f15a494317a8a43f617b9d4784429b9c5167ab
Blob: f336a9fbd195be4b914c8fc188227376416ed5ba
File: .github/pull_request_template.md
```

This demonstrates how Git stores data internally. A commit points to a tree object, the tree points to blobs, and blobs contain the actual file contents.

## Task 1.2 — Exploring .git

### HEAD Reference

```text
ref: refs/heads/feature/lab2
```

### Branch References

```text
feature
main
```

### Object Directories

```text
01
0a
0c
0e
0f
13
1a
24
27
37
```

### Loose Objects Count

```text
39
```

The .git directory contains all repository metadata, references, logs, and objects. Git stores content as objects identified by SHA hashes and uses references to track branches and commits.

## Task 1.3 — Recovery with Reflog

### Reflog Output

```text
24cef06 HEAD@{0}: reset: moving to HEAD~2
4975371 HEAD@{1}: commit: wip(lab2): more progress
9efba92 HEAD@{2}: commit: wip(lab2): start
```

### Recovery Command

```bash
git reset --hard 4975371
```

### Recovery Result

```text
HEAD is now at 4975371 wip(lab2): more progress
```

Git reflog tracks movements of HEAD and branch references. Even after a destructive reset, commits can usually be recovered from the reflog.

If git gc had run and garbage-collected unreachable commits before recovery, the lost commits could eventually be removed permanently. Reflog entries and unreachable objects are normally retained for a period of time, which provides a recovery window after mistakes.

## Task 2.1 — Signed Release Tag

### Tag Listing

```text
v0.0.1 tag commit
v0.1.0-lab2-lambada tag commit
```

### Tag Verification

```text
Good "git" signature for muhammadjonaslonov4@gmail.com with ED25519 key
```

The tag is annotated and cryptographically signed, allowing others to verify its authenticity and integrity.

## Task 2.2 — Rebase

### Before Rebase

```text
* 61c5644 docs: upstream moved while you worked
| * 4975371 wip(lab2): more progress
| * 9efba92 wip(lab2): start
|/
* 24cef06 docs: add PR template
```

### After Rebase

```text
* 8e89e59 wip(lab2): more progress
* 42d15dc wip(lab2): start
* 61c5644 docs: upstream moved while you worked
* 24cef06 docs: add PR template
```

Rebasing rewrote the commit history so that the feature branch appears to have been created from the latest version of main.

### Merge vs Rebase Reflection

I would use rebase when working on a private feature branch and I want a clean, linear history. I would use merge when preserving the exact history of collaboration is important or when multiple developers are already sharing the branch. Rebase improves readability, while merge preserves historical context.
important work
more important work
