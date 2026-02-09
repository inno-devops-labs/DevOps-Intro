# Lab 2 Submission

## Task 1 — Git Object Model Exploration (2 pts)

### Commands & Outputs

#### Create sample commit
```bash
echo "Test content" > test.txt
git add test.txt
git commit -m "Add test file"
git log --oneline -1
#### Inspect blob object (test.txt)
```bash
git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2
### What each object type represents

- **Blob**: Stores the raw contents of a file, without filename or directory information.
- **Tree**: Represents a directory by mapping names to blob or subtree hashes.
- **Commit**: Stores a snapshot reference (tree), metadata, and links commits into history.
### Analysis

Git stores data as content-addressed objects. File contents are stored as blobs, directories as trees, and commits reference trees and parent commits. This structure ensures integrity, deduplication, and efficient history tracking.
## Task 2 — Reset and Reflog Recovery (2 pts)

### Commits created for practice
- First commit
- Second commit
- Third commit

### Reset behavior

- **git reset --soft HEAD~1**  
  Removes the last commit from history, but keeps changes staged in the index.

- **git reset --mixed HEAD~1**  
  Removes the last commit from history and keeps changes unstaged in the working directory.

- **git reset --hard HEAD~1**  
  Completely removes the last commit and discards all related changes.

### Recovery using reflog

Using `git reflog`, the removed commit was found and successfully restored with `git reset --hard <commit_hash>`.
