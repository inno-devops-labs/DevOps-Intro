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

