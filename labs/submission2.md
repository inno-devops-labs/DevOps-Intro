# Task 1
albertshm@MacBook-Air-Albert DevOps-Intro % git log --oneline -1

c720480 (HEAD -> feature/lab2) Add test file
albertshm@MacBook-Air-Albert DevOps-Intro % git cat-file -p HEAD

tree b9bc0ecc4e06b9ebfda175ace5fd85a9cc33e5b8
parent 9424916e48032572f167cec385ab16023d9f9359
author Albert Shammasov <Shammasov.a21@gmail.com> 1770983890 +0300
committer Albert Shammasov <Shammasov.a21@gmail.com> 1770983890 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg5yazcdub2z3gTfqqXwTihzKifb
 1TqPp1OIi7oBGo9W8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQFBmp7n9Q+F2VkFddg0p4mS98/7iztttOvCK53INpBkyIHhp6LlCY4fPIHFHxiHYAi
 UwKjBkOjid+jidlsIeIQA=
 -----END SSH SIGNATURE-----

Add test file
albertshm@MacBook-Air-Albert DevOps-Intro % git cat-file -p b9bc0ecc4e06b9ebfda175ace5fd85a9cc33e5b8
100644 blob 8328d7bf1fdac3ffad894fda61ce1207030b436a    .DS_Store
040000 tree a5a1a748b2459aae9d2ef7faf33a0849b3230f9d    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 8106b5b5c75cba237c859bafe2c709c8bf090c67    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt

albertshm@MacBook-Air-Albert DevOps-Intro % git cat-file -p 2eec599a1130d2ff231309bb776d1989b97c6ab2

Test content
albertshm@MacBook-Air-Albert DevOps-Intro % git cat-file -p b9bc0ecc4e06b9ebfda175ace5fd85a9cc33e5b8

100644 blob 8328d7bf1fdac3ffad894fda61ce1207030b436a    .DS_Store
040000 tree a5a1a748b2459aae9d2ef7faf33a0849b3230f9d    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree 8106b5b5c75cba237c859bafe2c709c8bf090c67    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 2eec599a1130d2ff231309bb776d1989b97c6ab2    test.txt
albertshm@MacBook-Air-Albert DevOps-Intro % git cat-file -p c720480

tree b9bc0ecc4e06b9ebfda175ace5fd85a9cc33e5b8
parent 9424916e48032572f167cec385ab16023d9f9359
author Albert Shammasov <Shammasov.a21@gmail.com> 1770983890 +0300
committer Albert Shammasov <Shammasov.a21@gmail.com> 1770983890 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg5yazcdub2z3gTfqqXwTihzKifb
 1TqPp1OIi7oBGo9W8AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQFBmp7n9Q+F2VkFddg0p4mS98/7iztttOvCK53INpBkyIHhp6LlCY4fPIHFHxiHYAi
 UwKjBkOjid+jidlsIeIQA=
 -----END SSH SIGNATURE-----

Add test file


What each object type represents:

Blob: Stores the actual content of a file (binary large object). It's the file's data without metadata like filename.

Tree: Represents a directory - it lists filenames and links them to blob objects (for files) or other tree objects (for subdirectories).

Commit: A snapshot of the entire repository at a point in time. It points to a root tree, stores metadata (author, date, message), and links to parent commits.

How Git stores repository data:
Git stores everything as objects in the .git/objects directory. Each object has a unique SHA-1 hash derived from its content. Blobs store file content, trees store directory structures, and commits tie everything together with metadata. This creates an immutable, content-addressable filesystem where the entire history is just a chain of these objects.

Examples from my repository:

Blob (2eec599): Contains the actual text "Test content" from test.txt

Tree (b9bc0ec): Lists all files in the commit including test.txt, README.md, and directories like .github/, app/, labs/

Commit (c720480): Contains tree hash b9bc0ec, parent hash 9424916, author/committer info, timestamp, and message "Add test file"

# Task 2

albertshm@MacBook-Air-Albert DevOps-Intro % git switch -c git-reset-practice

Switched to a new branch 'git-reset-practice'
albertshm@MacBook-Air-Albert DevOps-Intro % echo "First commit" > file.txt && git add file.txt && git commit -m "First commit"

[git-reset-practice 86a724a] First commit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt
albertshm@MacBook-Air-Albert DevOps-Intro % echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit"

[git-reset-practice 59d40d7] Second commit
 1 file changed, 1 insertion(+)
albertshm@MacBook-Air-Albert DevOps-Intro % echo "Third commit"  >> file.txt && git add file.txt && git commit -m "Third commit"

[git-reset-practice d61b876] Third commit
 1 file changed, 1 insertion(+)
albertshm@MacBook-Air-Albert DevOps-Intro % git reset --soft HEAD~1
albertshm@MacBook-Air-Albert DevOps-Intro % git log --oneline      

59d40d7 (HEAD -> git-reset-practice) Second commit
86a724a First commit
c720480 (feature/lab2) Add test file
9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
54657dd chore: add pull request template 2
acd210a chore: add pull request template
bc17928 docs: add commit signing summary
842f09c docs: add commit signing summary
7e65698 docs: add commit signing summary
da05882 docs: add commit signing summary
e10862c docs: add commit signing summary
d6b6a03 Update lab2
87810a0 feat: remove old Exam Exemption Policy
1e1c32b feat: update structure
6c27ee7 feat: publish lecs 9 & 10
1826c36 feat: update lab7
3049f08 feat: publish lec8
da8f635 feat: introduce all labs and revised structure
04b174e feat: publish lab and lec #5
67f12f1 feat: publish labs 4&5, revise others
82d1989 feat: publish lab3 and lec3
3f80c83 feat: publish lec2
499f2ba feat: publish lab2
af0da89 feat: update lab1
74a8c27 Publish lab1
f0485c0 Publish lec1
31dd11b Publish README.md
albertshm@MacBook-Air-Albert DevOps-Intro % git reset --hard HEAD~1
HEAD is now at 86a724a First commit
albertshm@MacBook-Air-Albert DevOps-Intro % git reflog 
86a724a (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
59d40d7 HEAD@{1}: reset: moving to HEAD~1
d61b876 HEAD@{2}: commit: Third commit
59d40d7 HEAD@{3}: commit: Second commit
86a724a (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
c720480 (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice
c720480 (feature/lab2) HEAD@{6}: commit: Add test file
9424916 (origin/feature/lab1, feature/lab1) HEAD@{7}: checkout: moving from feature/lab1 to feature/lab2
9424916 (origin/feature/lab1, feature/lab1) HEAD@{8}: commit: chore: add pull request template 2
54657dd HEAD@{9}: commit: chore: add pull request template 2
acd210a HEAD@{10}: commit: chore: add pull request template
bc17928 HEAD@{11}: commit: docs: add commit signing summary
842f09c HEAD@{12}: commit: docs: add commit signing summary
7e65698 HEAD@{13}: commit: docs: add commit signing summary
da05882 HEAD@{14}: checkout: moving from main to feature/lab1
7b7b976 (origin/main, origin/HEAD, main) HEAD@{15}: commit (amend): docs: add lab1 submission stub
32d25de HEAD@{16}: commit: docs: add lab1 submission stub
d6b6a03 HEAD@{17}: checkout: moving from feature/lab1 to main
da05882 HEAD@{18}: commit: docs: add commit signing summary
e10862c HEAD@{19}: commit: docs: add commit signing summary
d6b6a03 HEAD@{20}: checkout: moving from main to feature/lab1
d6b6a03 HEAD@{21}: clone: from https://github.com/myavg/DevOps-Intro.git
albertshm@MacBook-Air-Albert DevOps-Intro % git reset --hard 59d40d7
HEAD is now at 59d40d7 Second commit


git switch -c git-reset-practice — created a new branch for experiments to avoid breaking my main work

echo "First commit" > file.txt && git add file.txt && git commit -m "First commit" — created first commit with a file

echo "Second commit" >> file.txt && git add file.txt && git commit -m "Second commit" — added second line and made second commit

echo "Third commit" >> file.txt && git add file.txt && git commit -m "Third commit" — added third line and made third commit

git reset --soft HEAD~1 - applied soft reset one commit back (removed third commit from history but kept changes)

git reset --hard HEAD~1 — applied hard reset one commit back (removed second commit AND all changes)

git reflog - viewed history of all HEAD movements to find lost commits

git reset --hard 59d40d7 — recovered to the second commit (found its hash in reflog)

git reflog:
86a724a (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
59d40d7 HEAD@{1}: reset: moving to HEAD~1
d61b876 HEAD@{2}: commit: Third commit
59d40d7 HEAD@{3}: commit: Second commit
86a724a (HEAD -> git-reset-practice) HEAD@{4}: commit: First commit
c720480 (feature/lab2) HEAD@{5}: checkout: moving from feature/lab2 to git-reset-practice

git log --oneline:
59d40d7 (HEAD -> git-reset-practice) Second commit
86a724a First commit
c720480 (feature/lab2) Add test file

What changed in the working tree, index, and history for each reset:
After git reset --soft HEAD~1 (removed third commit):
Working tree — unchanged, file.txt still had all three lines
Index — unchanged, third commit changes were still staged
History — changed, HEAD moved to second commit (59d40d7)
After git reset --hard HEAD~1 (removed second commit):
Working tree — changed, file.txt now had only the first line
Index — changed, cleared to match first commit
History — changed, HEAD moved to first commit (86a724a)

Recovery Analysis:
After --hard deleted my second commit, git reflog showed all my steps with hashes. I found 59d40d7 (second commit) and ran git reset --hard 59d40d7 to restore everything. Reflog is Git's safety net — it logs all HEAD movements for 90 days.

# Task 3

Graph:
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
:...skipping...
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
:...skipping...
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
:...skipping...
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
:...skipping...
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
:...skipping...
* aeb03fd (side-branch) Side branch commit
* 59d40d7 (HEAD -> git-reset-practice) Second commit
* 86a724a First commit
* c720480 (feature/lab2) Add test file
* 9424916 (origin/feature/lab1, feature/lab1) chore: add pull request template 2
* 54657dd chore: add pull request template 2
* acd210a chore: add pull request template
* bc17928 docs: add commit signing summary
* 842f09c docs: add commit signing summary
* 7e65698 docs: add commit signing summary
* da05882 docs: add commit signing summary
* e10862c docs: add commit signing summary
| * 7b7b976 (origin/main, origin/HEAD, main) docs: add lab1 submission stub
|/  
* d6b6a03 Update lab2
* 87810a0 feat: remove old Exam Exemption Policy
* 1e1c32b feat: update structure
* 6c27ee7 feat: publish lecs 9 & 10
* 1826c36 feat: update lab7
* 3049f08 feat: publish lec8
* da8f635 feat: introduce all labs and revised structure
* 04b174e feat: publish lab and lec #5
* 67f12f1 feat: publish labs 4&5, revise others
* 82d1989 feat: publish lab3 and lec3
* 3f80c83 feat: publish lec2
* 499f2ba feat: publish lab2
* af0da89 feat: update lab1
* 74a8c27 Publish lab1
* f0485c0 Publish lec1
* 31dd11b Publish README.md
~

Commit messages list:
aeb03fd - Side branch commit
59d40d7 - Second commit
86a724a - First commit
c720480 - Add test file
7b7b976 - docs: add lab1 submission stub (main branch)

Reflection:
The graph helps visualize how branches diverge and converge. I can clearly see that side-branch branched off from git-reset-practice, and there's also a separate main branch history that later merged back. Without the graph, I'd just see a flat list of commits and wouldn't understand the parallel development paths.


# Task 4

Tag Names and Commands Used:
git tag v1.0.0 — created lightweight tag v1.0.0
git push origin v1.0.0 — pushed tag to GitHub

Associated Commit Hash:
Tag v1.0.0 points to commit c720480 ("Add test file")

Why Tags Matter:
Tags mark specific points in history as important — usually for releases. They enable versioning (v1.0.0, v1.1.0), trigger CI/CD pipelines to build/deploy, and generate release notes. Unlike branches, tags don't move, so they permanently mark a commit.

# Task 5

albertshm@MacBook-Air-Albert DevOps-Intro % git switch -c cmd-compare
Switched to a new branch 'cmd-compare'
albertshm@MacBook-Air-Albert DevOps-Intro % git switch -
Switched to branch 'git-reset-practice'
albertshm@MacBook-Air-Albert DevOps-Intro % git checkout -b cmd-compare-2
Switched to a new branch 'cmd-compare-2'
albertshm@MacBook-Air-Albert DevOps-Intro % echo "scratch" >> demo.txt
albertshm@MacBook-Air-Albert DevOps-Intro % git restore demo.txt
albertshm@MacBook-Air-Albert DevOps-Intro % git restore --staged demo.txt
albertshm@MacBook-Air-Albert DevOps-Intro % git restore --source=HEAD~1 demo.txt


git status:
On branch cmd-compare-2
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        demo.txt
        labs/submission2.md

git branch:
  cmd-compare
* cmd-compare-2
  feature/lab1
  feature/lab2
  git-reset-practice
  main
  side-branch

When to Use Each Command:
git switch - use ONLY for switching between branches. It's safe and focused.

git checkout - legacy command that does too many things (switching branches AND restoring files). Avoid for branch operations, use switch instead.

git restore - use for discarding changes in tracked files or unstaging files. Don't use for branch switching.

# Task 6

Why starring repositories matters in open source:
Stars show appreciation to maintainers, help others discover popular projects, and act like bookmarks for tools you want to remember.

How following developers helps in team projects and professional growth:
Following lets you see their public work, learn from their code, stay updated on their projects, and build professional connections in the community.