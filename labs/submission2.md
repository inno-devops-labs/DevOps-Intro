# Lab 2 Submission
## Task 1: Git Object Model Exploration
### Command outputs for object inspection:
#### 1. Commit Object
arinapetuhova@192 DevOps-Intro % git log --oneline -1

74c38e3 (HEAD -> feature/lab2) Add test file

arinapetuhova@192 DevOps-Intro % git cat-file -p 74c38e3

tree b660713fc594e96a202a3eb9a00bfdceee997270

parent fcfd20b880bf4ce1ea665b92c0f087db645d79c4

author Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com> 1770370868 +0300

committer Arina Petuhova <119685834+arinapetukhova@users.noreply.github.com> 1770370868 +0300

gpgsig -----BEGIN SSH SIGNATURE-----

 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgUDPLkiD0daseOoV9XP0Y0kgQg1

 G2jn3Herr0uZ2bnroAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5

 AAAAQEE3uLqt0EDdiEL5Pz0DKJhHTAF9m3fNsvV1cNAq9d2OdA8ckqtH+KPp7kUrBnBfUV

 lG3dPPezDBMLQ3hTj1lQs=

 -----END SSH SIGNATURE-----

Add test file

#### 2. Tree Object
arinapetuhova@192 DevOps-Intro % git cat-file -p b660713fc594e96a202a3eb9a00bfdceee997270

100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md

040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app

040000 tree f0fbfea6739bbc15d0f4a5408cdb109a9c6cbb4f    labs

040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures

100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

#### 3. Blob Object
arinapetuhova@192 DevOps-Intro % git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2

Test content

### Object Type Explanations

- **Blob**: Represents file content - a snapshot of a file at a specific point in time.
- **Tree**: Represents directory structure - a listing of files (blobs) and subdirectories (trees) with their permissions and names.
- **Commit**: Represents a snapshot of the repository - metadata including author, timestamp, parent commits, and a pointer to the root tree.

### Git Storage Analysis
Git stores repository data as a directed acyclic graph of objects where commits point to trees, trees point to blobs and other trees, and blobs contain actual file content. Each object is content-addressed using hashes, making Git a content-addressable filesystem where identical content is stored only once.

### Example Object Content

**Blob Example**: `2eec599a1130d2ff231309bb776d1989b97c6ab2` contains the exact file content "Test content".

**Tree Example**: `b660713fc594e96a202a3eb9a00bfdceee997270` shows the repository structure with 2 blobs (README.md and test.txt) and 3 trees (app, labs, lectures).

**Commit Example**: `74c38e3` contains metadata including parent commit `fcfd20b`, author information, timestamp, GPG signature, and commit message "Add test file".

## Task 2: Reset and Reflog Recovery

## Task 3: Visualize Commit History
## Task 4: Tagging Commits
## Task 5: git switch vs git checkout vs git restore
## Task 6: GitHub Community Engagement