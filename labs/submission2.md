## Task 1 — Git Object Model Exploration (blobs / trees / commits)

### 1.1 Create sample commit
Commands:
```bash
echo "Test content" > labs/labs/test.txt
git add labs/labs/test.txt
git commit -m "Add test file"
```

### 1.2 Inspect Git objects

#### Commit object

Commit hash:

```txt
444d95f2dde13085c80adf0ebaa9847ea5910087
```

Command:

```bash
git cat-file -p 444d95f2dde13085c80adf0ebaa9847ea5910087
```

Output:

```txt
tree 7f704bdb3b000983f61d02b382cea7a45496e9fe
parent 39af3b3c8a6298eec9088c337b1c8203d18c2751
author vizitei-dmitri <polarevia@bk.ru> 1770978514 +0300
committer vizitei-dmitri <polarevia@bk.ru> 1770978514 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgY/bQUzg/l2aobFLEIhuGQIRHBZ
 dGs7jYsCpPNn1HZk8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQBwUrYQxz1m4KEVClnVlSjjYYlBO9b1beAsO7Z1tiD0xZcWmxAx2fPfRGPdGjAu+4d
 0JXfQh0W6pYGkKibA2awE=
 -----END SSH SIGNATURE-----

Add test file
```

#### Tree object (root tree referenced by the commit)

Tree hash:

```txt
7f704bdb3b000983f61d02b382cea7a45496e9fe
```

Command:

```bash
git cat-file -p 7f704bdb3b000983f61d02b382cea7a45496e9fe
```

Output:

```txt
040000 tree 739d3005cd6eea94be3f8423a95eb89bc051c98b	.github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb	README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c	app
040000 tree d83aa01d81dd5a33f5c0ccd1177f4fb91b9f628e	labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63	lectures
```

#### Tree objects for `labs/` and `labs/labs/` (to locate `test.txt`)

Command:

```bash
git cat-file -p d83aa01d81dd5a33f5c0ccd1177f4fb91b9f628e
```

Output:

```txt
100644 blob aa6b7b5c478b439d2c1e9b4f085257782dd68d25	lab1.md
100644 blob cf1ba99be683932b0a1e1cfd84f0d6f0dc0d184f	lab10.md
100644 blob ca6bbf33cb79a950fbf3c517e6b174ac65f5334b	lab11.md
040000 tree 16bf9eb348f7da4acbec0a94fc4a09e46c40064f	lab11
100644 blob fcd2509fd7a30ea3b5cc9e879f97fbb32d3e660d	lab12.md
040000 tree 129069dd8e40511c9ab6c889b375532b1d68fde3	lab12
100644 blob 3128f48b832e6592d02ae82a18f9b89af82c9658	lab2.md
100644 blob 6e453f5c97f02a4bca77db29549154072771ad4a	lab3.md
100644 blob 3aa4439565d04ff637e909ffc164d59a60749239	lab4.md
100644 blob 0435c3fcbd5d21b21cf253af0544a6536247cdb9	lab5.md
100644 blob af90a7fa02f582cd3d31f4d9f71360878f031e92	lab6.md
100644 blob ee11bdfb0d71048268ec439ad0c4ee2f7bf6fd1b	lab7.md
100644 blob 9df09119213b81f88f6b61c89f3bcf223a32ecf6	lab8.md
100644 blob 12e1b875e40d5ef91f11c36fb259f23069fc458f	lab9.md
040000 tree fcfdf1d1a05846f2059603b98e0c1f9f2bc881c8	labs
```

Command:

```bash
git cat-file -p fcfdf1d1a05846f2059603b98e0c1f9f2bc881c8
```

Output:

```txt
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2	test.txt
```

#### Blob object for `labs/labs/test.txt`

Blob hash:

```txt
2eec599a1130d2ff231309bb776d1989b97c6ab2
```

Command:

```bash
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
```

Output:

```txt
Test content
```

### Explanation

* **Blob**: Stores the file content (raw bytes). It does not store filenames.
* **Tree**: Stores a directory listing (filenames, modes) and pointers to blobs/other trees.
* **Commit**: Stores metadata (author/committer, message) and points to a tree snapshot plus parent commit(s).

### Short analysis (how Git stores data)

Git stores data as content-addressed objects. A commit points to a tree (project snapshot), and trees point to blobs (file contents) and subtrees (directories). Filenames live in trees, not in blobs.


## Task 2 — Reset and Reflog Recovery

### Setup (practice branch)
Commands:
```bash
git switch -c git-reset-practice

echo "First commit" > file.txt
git add file.txt
git commit -m "First commit"

echo "Second commit" >> file.txt
git add file.txt
git commit -m "Second commit"

echo "Third commit" >> file.txt
git add file.txt
git commit -m "Third commit"
```

Initial log:

```txt
8e2d1df (HEAD -> git-reset-practice) Third commit
d96eeba Second commit
99b3e1b First commit
444d95f (feature/lab2) Add test file
39af3b3 (origin/main, origin/HEAD, main) chore: add PR template
```

### Soft reset (keep index + working tree)

Command:

```bash
git reset --soft HEAD~1
git status
git log --oneline --decorate -5
```

Status + log after soft reset:

```txt
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   file.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	submission2.md

d96eeba (HEAD -> git-reset-practice) Second commit
99b3e1b First commit
444d95f (feature/lab2) Add test file
39af3b3 (origin/main, origin/HEAD, main) chore: add PR template
d6b6a03 (upstream/main) Update lab2
```

Staged diff (shows what stayed in the index):

```bash
git diff --cached
```

Output:

```diff
diff --git a/labs/labs/file.txt b/labs/labs/file.txt
index 6a3adff..5b3c010 100644
--- a/labs/labs/file.txt
+++ b/labs/labs/file.txt
@@ -1,2 +1,3 @@
 First commit
 Second commit
+Third commit
```

### Recreate commit (to demonstrate hard reset)

Command:

```bash
git commit -m "Recreate third commit"
git log --oneline --decorate -5
```

Log:

```txt
adae85e (HEAD -> git-reset-practice) Recreate third commit
d96eeba Second commit
99b3e1b First commit
444d95f (feature/lab2) Add test file
39af3b3 (origin/main, origin/HEAD, main) chore: add PR template
```

### Hard reset (discard index + working tree)

Command:

```bash
git reset --hard HEAD~1
git status
git log --oneline --decorate -5
```

Status + log after hard reset:

```txt
HEAD is now at d96eeba Second commit
On branch git-reset-practice
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	submission2.md

nothing added to commit but untracked files present (use "git add" to track)
d96eeba (HEAD -> git-reset-practice) Second commit
99b3e1b First commit
444d95f (feature/lab2) Add test file
39af3b3 (origin/main, origin/HEAD, main) chore: add PR template
d6b6a03 (upstream/main) Update lab2
```

### Reflog recovery

Command:

```bash
git reflog -10
```

Output:

```txt
d96eeba (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
adae85e HEAD@{1}: commit: Recreate third commit
d96eeba (HEAD -> git-reset-practice) HEAD@{2}: reset: moving to HEAD~1
8e2d1df HEAD@{3}: commit: Third commit
d96eeba (HEAD -> git-reset-practice) HEAD@{4}: commit: Second commit
99b3e1b HEAD@{5}: commit: First commit
444d95f (feature/lab2) HEAD@{6}: checkout: moving from feature/lab2 to git-reset-practice
444d95f (feature/lab2) HEAD@{7}: commit: Add test file
39af3b3 (origin/main, origin/HEAD, main) HEAD@{8}: checkout: moving from main to feature/lab2
39af3b3 (origin/main, origin/HEAD, main) HEAD@{9}: checkout: moving from feature/lab1 to main
```

Recovery command:

```bash
git reset --hard adae85e
git log --oneline --decorate -5
cat file.txt
```

Result:

```txt
adae85e (HEAD -> git-reset-practice) Recreate third commit
d96eeba Second commit
99b3e1b First commit
444d95f (feature/lab2) Add test file
39af3b3 (origin/main, origin/HEAD, main) chore: add PR template
First commit
Second commit
Third commit
```

### Summary (working tree / index / history)

* `git reset --soft HEAD~1` moved `HEAD` back but kept the changes from the removed commit staged (index preserved) and also kept them in the working tree.
* `git reset --hard HEAD~1` moved `HEAD` back and made the index + working tree match the target commit, discarding local changes from the removed commit.
* `git reflog` recorded previous `HEAD` positions, so I could restore the state by resetting back to commit `adae85e`.


## Task 3 — Visualize Commit History

### Commands
```bash
git switch -c side-branch
echo "Branch commit" >> history.txt
git add history.txt
git commit -m "Side branch commit"

git switch -
git log --oneline --graph --all --decorate -10
```

### Graph snippet

```txt
* fa40a95 (side-branch) Side branch commit
* adae85e (HEAD -> git-reset-practice) Recreate third commit
* d96eeba Second commit
* 99b3e1b First commit
* 444d95f (feature/lab2) Add test file
| * f566f0e (origin/feature/lab1, feature/lab1) docs: finalize lab1 submission
| * 5609f55 docs: finalize lab1 submission
| * 1861a66 docs: add final PR link
| * df1c7b3 docs: trigger verified badge
| * bfa2223 docs: update submission for verification
```

### Commit messages observed

* Side branch commit
* Recreate third commit
* Second commit
* First commit
* Add test file

### Reflection

The `--graph --all` view makes branching structure visible at a glance. It helps quickly see which commits belong to which branch and how different lines of development relate to each other.


## Task 4 — Tagging Commits

### Commands
```bash
git tag v1.0.0
git show-ref --tags
git rev-parse v1.0.0^{commit}
git push origin v1.0.0

echo "Another change" >> test.txt
git add test.txt
git commit -m "Update test file"
git tag v1.1.0
git push origin v1.1.0
```

### Tag refs and commit hashes

From `git show-ref --tags`:

```txt
adae85e221627d330f1d77527aefb0545a5ec191 refs/tags/v1.0.0
```

From `git rev-parse v1.0.0^{commit}`:

```txt
adae85e221627d330f1d77527aefb0545a5ec191
```

Tags created:

* `v1.0.0` -> `adae85e221627d330f1d77527aefb0545a5ec191`
* `v1.1.0` -> (tagged after commit `Update test file`; verify with `git rev-parse v1.1.0^{commit}`)

Why tags matter:
Tags provide stable, human-friendly names for important commits (releases). They are commonly used for versioning, release notes, and CI/CD triggers.

---

## Task 5 — git switch vs git checkout vs git restore

### Commands and outputs

#### Branch switching (`git switch`)

```bash
git branch
git switch side-branch
git switch -
```

Output:

```txt
  feature/lab1
  feature/lab2
* git-reset-practice
  main
  side-branch
Switched to branch 'side-branch'
Switched to branch 'git-reset-practice'
```

#### Restoring files (`git restore`)

I created `history.txt` as a new untracked file, so `git restore history.txt` failed because the file was not known to Git yet.

```bash
echo "WIP" >> history.txt
git status
git restore history.txt
git status
```

Output:

```txt
On branch git-reset-practice
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	history.txt
	submission2.md

nothing added to commit but untracked files present (use "git add" to track)
error: pathspec 'history.txt' did not match any file(s) known to git
On branch git-reset-practice
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	history.txt
	submission2.md

nothing added to commit but untracked files present (use "git add" to track)
```

Then I demonstrated unstage with `git restore --staged`:

```bash
echo "STAGED" >> history.txt
git add history.txt
git status
git restore --staged history.txt
git status
```

Output:

```txt
On branch git-reset-practice
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   history.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	submission2.md

On branch git-reset-practice
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	assets/
	history.txt
	submission2.md

nothing added to commit but untracked files present (use "git add" to track)
```

#### Legacy command (`git checkout`)

```bash
git checkout -b checkout-legacy-demo
git checkout feature/lab2
```

Output:

```txt
Switched to a new branch 'checkout-legacy-demo'
Switched to branch 'feature/lab2'
```

### When to use what

* `git switch`: use for switching/creating branches (clear purpose, modern replacement for branch-related `checkout`).
* `git restore`: use for file-level operations (discard working tree changes, or unstage with `--staged`).
* `git checkout`: legacy multi-purpose command (branches + files). Still works, but `switch/restore` are more explicit and reduce mistakes.

```
```
