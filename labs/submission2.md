# Lab 2 Submission

## Task 1 --- Git Object Model Exploration

### Commands

``` sh
echo "Test content" > test.txt
git add test.txt
git commit -m "Add test file"
git log --oneline -1
git cat-file -p HEAD
git cat-file -p edfdd8ae877cc522b0ead2e18c764afa356a252b
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
```

### Outputs

**Commit object:**

    tree edfdd8ae877cc522b0ead2e18c764afa356a252b
    Add test file

**Tree object (excerpt):**

    100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

**Blob object:**

    Test content

### Explanation

-   **Blob:** stores raw file content.
-   **Tree:** directory snapshot mapping names → blobs/trees.
-   **Commit:** metadata + pointer to root tree (repo snapshot).

**Storage model:** Git stores file data as blobs, directory structure as
trees, and commits reference trees to represent full project snapshots.








## Task 2 — Reset and Reflog Recovery

### Commands + key outputs

Initial history:
```sh
git log --oneline -5
c92cc02 (HEAD -> git-reset-practice) Third commit
6b137ff Second commit
da62d38 First commit
````

Soft reset (move HEAD back, keep index + working tree):

```sh
git reset --soft HEAD~1
git log --oneline -5
6b137ff (HEAD -> git-reset-practice) Second commit
da62d38 First commit

git status
Changes to be committed:
  modified: file.txt
```

Hard reset (move HEAD back, discard index + working tree changes):

```sh
git reset --hard HEAD~1
git log --oneline -5
da62d38 (HEAD -> git-reset-practice) First commit

git status
nothing to commit, working tree clean
```

Reflog + recovery:

```sh
git reflog -10
c92cc02 HEAD@{2}: commit: Third commit
...

git reset --hard c92cc02
git log --oneline -5
c92cc02 (HEAD -> git-reset-practice) Third commit
6b137ff Second commit
da62d38 First commit
```

### Explanation

* `git reset --soft`: история (HEAD) откатывается, но изменения остаются в **index (staged)** и рабочей директории.
* `git reset --hard`: история откатывается и изменения удаляются из **index** и **working tree**.
* `git reflog` показывает прошлые положения HEAD, поэтому можно восстановиться, сделав `git reset --hard <hash>` на нужное состояние.





## Task 3 — Visualize Commit History

Graph:
```sh
git log --oneline --graph --all --decorate
* dae0f56 (side-branch) Side branch commit
* d580171 (HEAD -> feature/lab2) docs: add task2
| * c92cc02 (git-reset-practice) Third commit
| * 6b137ff Second commit
| * da62d38 First commit
|/  
* 0bb29fa docs: add task1
* ed0929f Add test file
````

Commit messages (from the graph): `Side branch commit`, `docs: add task2`, `Third commit`, `Second commit`, `First commit`, `docs: add task1`, `Add test file`.

Reflection: `--graph --all` makes it clear where branches diverge and which commits belong to each branch.






## Task 4 — Tagging Commits

Commands:
```sh
git tag v1.0.0
git show --oneline --no-patch v1.0.0
git push origin v1.0.0
````

Tag info:

```
e7e523d docs: add task3
```

Why tags matter: tags mark release points, enable versioning, and are commonly used by CI/CD pipelines and release notes.




## Task 5 — switch vs checkout vs restore

### git switch (modern branch switching)
```sh
git switch -c cmd-compare
git switch -
````

Switch cleanly toggles between branches.

### git checkout (legacy)

```sh
git checkout -b cmd-compare-2
git switch -
```

Checkout can create/switch branches but is overloaded.

### git restore (file operations)

Working tree restore attempt:

```sh
echo "scratch" >> demo.txt
git restore demo.txt
```

Result: failed because the file was untracked.

Index restore:

```sh
echo "scratch2" >> demo.txt
git add demo.txt
git restore --staged demo.txt
```

### When to use each

* `git switch` — switching branches (clear intent).
* `git restore` — restoring files or index state.
* `git checkout` — legacy multi-purpose command.
