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
