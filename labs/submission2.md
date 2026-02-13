# Lab 2 — Version Control & Advanced Git

## Task 1 — Git Object Model
- Commit inspected: 27583ba
- `git cat-file -p HEAD` → tree 7da286dd..., parent c225d7b..., author/committer lana, message “Add test file”.
- Tree 7da286dd... lists: .github (tree 03479168...), README.md (blob 6e60bebe...), app (tree a1061247...), labs (tree e047e4b0...), lectures (tree d3fb3722...), test.txt (blob 2eec599a...).
- Parent commit c225d7b... → tree 452cc25d..., parent a64a660..., message “add: task 2 report for lab 1”.
- Object examples: blob 2eec599a... = `test.txt` contents; tree 7da286dd... = folder layout; commit 27583ba = metadata + links.
- Git stores blobs (file bytes), trees (structure), commits (history links) inside `.git/objects` addressed by hashes.

## Task 2 — Reset & Reflog
Branch `git-reset-practice`:
1) Three commits: ce9989d “First”, 8128d3b “Second”, 1cb2fc9 “Third”.
2) `git reset --soft HEAD~1` → history at 8128d3b; index keeps staged “Third”; working tree unchanged.
3) `git reset --hard HEAD~1` → only ce9989d; index + working tree cleaned.
4) `git reflog` shows `HEAD@{2}=1cb2fc9`.
5) `git reset --hard 1cb2fc9` restores all three commits.

## Task 3 — History Graph
```
* b2cc88a (side-branch) Side branch commit
| * 1cb2fc9 (git-reset-practice) Third commit
| * 8128d3b Second commit
| * ce9989d First commit
|/
* 27583ba (HEAD -> feature/lab2) Add test file
* c225d7b (main) add: task 2 report for lab 1
```
Graph clarifies branch split/merge and commit ownership.

## Task 4 — Tags
- Commands: `git switch feature/lab2`; `git tag v1.0.0`; `git push origin v1.0.0`; `git show v1.0.0 --oneline`.
- Tag `v1.0.0` → commit 27583ba (“Add test file”).
- Tags mark release points and can trigger CI/CD/release notes.

## Task 5 — switch vs checkout vs restore
- Ran: `git switch -c cmd-compare`; `git checkout -b cmd-compare-2`; created/committed `demo.txt`; `git restore demo.txt`; `git restore --staged demo.txt`.
- Usage: `git switch` = create/swap branches only; `git checkout` = legacy, mixes branch + file ops; `git restore` = discard or unstage file changes, keeps branch ops separate.

## Task 6 — GitHub Community
- Stars bookmark useful repos, boost visibility, and show support to maintainers.
- Following profs/TAs/classmates surfaces their activity, aids coordination, and grows professional network/learning.
