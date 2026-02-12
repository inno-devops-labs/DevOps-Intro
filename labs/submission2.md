# Task 1
### Blob of file
Input: `git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2`

Ouput: `Test Content`


### Tree 
Input: `git cat-file -p 2f30b2f39f066647328c12be87f1e7de02190bdd`

Output:
```bash
040000 tree 1d8119ae1a1b35680094503c8fac56ab627d8610    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
```

### Commit
Input: `git cat-file -p 0987b8f`

```tree 2f30b2f39f066647328c12be87f1e7de02190bdd
parent 1f5c1e65e4b5cce5335342b4aa6f28c2b7430a69
author Vladimir Paskal <vpd63@inbox.ru> 1770927801 +0300
committer Vladimir Paskal <vpd63@inbox.ru> 1770927801 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
....
 -----END SSH SIGNATURE-----

Add test file
```

### Analysis
Blob: stores file contents(e.g. raw data "Test content")
Tree: stores directory structure (e.g. filename + permissions + blob hash)
Commit: stores snapshot metadata(e.g. tree hash, author, message, parent)

Git stores data as a content-addressable filesystem. 
Each object is identified by a SHA hash of its content.
Blobs store file data, trees store directory listings with file names and 
permissions pointing to blobs, and commits store snapshots by referencing 
tree objects. This immutable object model enables efficient branching,
history tracking, and data integrity verification.


# Task 2
 Input: `git reset --soft HEAD~1`

Output: *no output*

What changed: HEAD moved to parent commit, 
but index (staging area) and working tree unchanged. 
File changes from "Third commit" are now staged.


Input: `git reset --hard HEAD~1`

Output: `HEAD is now at 5eeb8cd First commit`

What changed: HEAD moved, index reset, working tree completely overwritten.
All changes after "First commit" are discarded.

Input: `git reflog`

Output:
```
5eeb8cd (HEAD -> git-reset-pratice) HEAD@{0}: reset: moving to HEAD~1
f6d14bf HEAD@{1}: reset: moving to HEAD~1
a4ade16 HEAD@{2}: commit: Third commit
f6d14bf HEAD@{3}: commit: Second commit
5eeb8cd (HEAD -> git-reset-pratice) HEAD@{4}: commit: First commit
```

Input: `git reset --hard a4ade16`

Output: `HEAD is now at a4ade16 Third commit`

Recovery Analysis: The reflog tracks every HEAD movement 
locally for some time. Even after --hard resets that "lose" commits, 
we can recover by referencing the reflog hash. 
This is a safety that makes git extremely resistent to human error.

# Task 3
Input: 
```
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt && git commit -m "Side branch commit"
git switch -
git log --oneline --graph --all
```

Output:
```
* d95a9e7 (side-branch) Side branch commit
* a4ade16 (HEAD -> git-reset-pratice) Third commit
* f6d14bf Second commit
* 5eeb8cd First commit
* 0987b8f (feature/lab2) Add test file
* 1f5c1e6 (origin/main, origin/HEAD, main) chore: change temlate
* 793c499 chore: add PR template
| * 7c5efa2 (origin/feature/lab1, feature/lab1) docs: add image of template
| * 2f034bd docs: add lab doc
|/  
* d6b6a03 Update lab2
```

Reflection: The graph visualization transforms abstract 
commit relationships into an intuitive, visual map. 
It instantly reveals project structure, parallel development streams, 
and integration points-far more effective than reading timestamps 
and commit messages alone. This is invaluable for understanding complex
project histories and debugging integration issues.


# Task 4
Input: 
```
git tag v1.0.0
git push origin v1.0.0
```

Output:
```
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 8 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (12/12), 3.08 KiB 
| 3.08 MiB/s, done.
Total 12 (delta 7), reused 0 (delta 0), 
pack-reused 0
remote: Resolving deltas: 100% (7/7), co
mpleted with 1 local object.
To github.com:ghshark63/DevOps-Intro.git
 * [new tag]         v1.0.0 -> v1.0.0
```
Why tags matter: Tags create immutable, 
human-readable references to specific points in 
history-typically releases. They enable precise version tracking, simplify CI/CD pipelines (build on tag push), and provide clear documentation for changelogs and release notes. Unlike branches, tags don't move, ensuring long-term reproducibility.

# Task 5
Input: 
```
git switch -c cmd-compare   # create and switch
git switch -                # toggle back to previous branch`
```

Output:
```
Switched to a new branch 'cmd-compare'
Switched to branch 'git-reset-pratice'
```

Input: `git branch`

Output:
```
  feature/lab1
  feature/lab2
* git-reset-pratice
  main
  side-branch
```

Recommendation: Use switch and restore for all new work. 
They follow the principle of separation of concerns—each command 
does exactly one thing clearly. checkout is convenient but confusing, 
especially for beginners.
