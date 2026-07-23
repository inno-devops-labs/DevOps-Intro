# Lab 2 — Version Control Deep Dive: Internals, Recovery, Rebase

  

## Task 1 — Git Object Model + Reflog Recovery

  

### 1.1 Exploring Repo's plumbing

  

```bash

$ git rev-parse HEAD # prints the full commit hash of the commit currently checked out as HEAD

2184bc3020e48aaf2b45eb53c2bb74b0dfea7bdc

  
  

$ git cat-file -t HEAD # prints the type of the Git object that HEAD points to.

commit

  
  

$ git cat-file -p HEAD # pretty-prints the contents of the Git object that HEAD points to

tree e098de2ba5d7e1cff9486210d1475c4540fd38b8 # tree object for the commit (tree SHA)

parent 36b4d4ed35f92158187761d06bae1cec768eb09c # This is the previous commit (parent SHA)

author Ahmad Sarhan <ahmadhasansarhana@gmail.com> 1782946361 +0300 # Author

committer Ahmad Sarhan <ahmadhasansarhana@gmail.com> 1782946361 +0300

gpgsig -----BEGIN SSH SIGNATURE----- # commit signature

 U1NIU0lHAAAAAQAAAZcAAAAHc3NoLXJzYQAAAAMBAAEAAAGBALK3wFYhYK9fs78w3wkNN9

 CpI+xdCDRAlul6ievBHN/zadooQJcvWBAxDVFNdisahqjjbWYD2a3MS+7f6+bnN7o48ayX

 9hvTbxaeNJbv+Is5iRF/8WbjGV1+uSA+69DQsYNX1elliJXoRibe+w6EothuU8LIHYbCzO

 fF1+xTq40cNZuY0HhF3PWFHrM8PLAUABgFgatmIynznMhfXrFJB+mKX4CQa8HNDDhBTk/j

 ohaQt1YdYh3zyeUE6pKj1XnYyWWjJzDZWLm9w9jvzqWkVg9PdTxm2AOBIu4fLrjECwRBnl

 aDZPBcHzOblYD5oSCMSQMksZyg2osJu/5SAB3gQQo5xacK/fmIwkfNau8AArCydiPg15Ks

 FFJlZJ3je/5Prb2g9lhA4D2f8L7T2AS79vuWgwsLYoFxwTPqQ0JndkWSrrkGaYRVghGHJu

 UWJ86UGF/pSmqznyzinO6XzZ+KAtBQwMooNo4esDthr6PllrC5AIB3XbrfhpGGrQiPg037

 wwAAAANnaXQAAAAAAAAABnNoYTUxMgAAAZQAAAAMcnNhLXNoYTItNTEyAAABgB26lnM3aZ

 Oe5QJY5X2RD6jXd1mLQpqu9Logd8mHXQXi5H69ikR7CH0FlPv8g8c8bNCrCb7hPSpdnUnA

 7TEIpNW22ds0ukUXmcPxEXbpY8BcNZ1T3T/l/ccZJPeFGyTppXSpCPRfUnMUUiwNUq4qAf

 Rx9inyYbivjfiYZsiaEeONiNsC9B7pzO5u8gWgwFQldNIhb/Di8z7jOV3Lbsh/wnR5n/KV

 QvU/F49MLVk5hQSjN4WkyCJPWmQpWcJ0NB8ptML0reC5caSNf/3e0VjO3Kn+O8xIfGAesB

 jfpQe3xrkc4azflFfJ8I5eL1vksPBQ3dZJTEdK8la5LX5YoI0lhc3K/kadTkR9bdvyiocx

 5XqEGTL3umKSKyWVy4RYSSvkHeu9h0236uu0+yIavo++I0ZYnzYrctAu/i3K4o6xyIZR0W

 QcY79KnRp38Kq5sm4Y20z6Mnq3gzXm/CB4gWrFCqqDoL+cp/QyyDCcfR38QB04Spi/9M10

 /tXDBetvpaY8MQ==

 -----END SSH SIGNATURE-----

  

docs(lab1): complete task3

  

Signed-off-by: Ahmad Sarhan <ahmadhasansarhana@gmail.com>

  
  

$ git cat-file -p e098de2ba5d7e1cff9486210d1475c4540fd38b8  # pretty-prints a Git tree object.

100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore

100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md

040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app

040000 tree 89bc50bc368eff78a23dcf65c83a925674de2e66    labs

040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

040000 tree 60f1f7f350aa6b3db0b98b650963b0b621663b29    screenshots

040000 tree 2c0d6decede7b2da41e0e79f95a88c87ba50b21d    submissions

# <mode> <type> <object-sha> <name>

  
  

$ git cat-file -p d10c04c6e7e0014f4fe883599c11747c15012d4e # README.md

# DevOps Intro — Modern DevOps Practices Through One Project

  

[![Course](https://img.shields.io/badge/Course-DevOps%20Intro-blue)](#course-roadmap)

[![Project](https://img.shields.io/badge/Project-QuickNotes%20(Go)-success)](#the-project-quicknotes)

[![Duration](https://img.shields.io/badge/Duration-10%20Weeks-lightgrey)](#course-roadmap)

[![Grading](https://img.shields.io/badge/Grading-70--14--5--30--30-orange)](#grading)

...

```

  

### 1.2: Look inside `.git/`

  

```bash

$ ls -la .git/ # high level directory structure

total 60

drwxr-xr-x  7 sarhan sarhan 4096 Jul  6 21:59 .

drwxr-xr-x  8 sarhan sarhan 4096 Jul  2 01:23 ..

-rw-r--r--  1 sarhan sarhan   86 Jul  2 01:52 COMMIT_EDITMSG

-rw-r--r--  1 sarhan sarhan  215 Jul  6 21:58 FETCH_HEAD

-rw-r--r--  1 sarhan sarhan   29 Jul  6 21:59 HEAD

-rw-r--r--  1 sarhan sarhan   41 Jul  2 01:53 ORIG_HEAD

-rw-r--r--  1 sarhan sarhan  594 Jul  6 21:59 config

-rw-r--r--  1 sarhan sarhan   73 Jun 28 17:38 description

drwxr-xr-x  2 sarhan sarhan 4096 Jun 28 17:38 hooks

-rw-r--r--  1 sarhan sarhan 3311 Jul  2 01:52 index

drwxr-xr-x  2 sarhan sarhan 4096 Jun 28 17:38 info

drwxr-xr-x  3 sarhan sarhan 4096 Jun 28 17:38 logs

drwxr-xr-x 47 sarhan sarhan 4096 Jul  6 21:58 objects       # Stores commits, trees, blobs, and tags

-rw-r--r--  1 sarhan sarhan  112 Jun 28 17:38 packed-refs  

drwxr-xr-x  5 sarhan sarhan 4096 Jun 28 17:38 refs          # Stores branches and tags

  
  

$ cat .git/HEAD  

ref: refs/heads/feature/lab2 # Points to the current branch

  
  

$ ls .git/refs/heads/ # branches

feature  main

  

$ ls .git/refs/heads/ -R

.git/refs/heads/:

feature  main

  

.git/refs/heads/feature:

lab1  lab2

  
  
  

$ ls .git/objects/ | head # subdirs by first 2 SHA chars

00

05

0a

0c

0e

0f

13

14

1a

1c

  
  

$ find .git/objects -type f | wc -l # counts how many files exist inside Git’s object database

50

  

$ git count-objects # counts only loose objects

47 objects, 268 kilobytes

# Loose objects are individual Git objects stored as separate compressed files, before Git packs them together into packfiles.

```

  

### 1.3: Simulate disaster + recover

```bash
$ echo "important work" > submissions/lab2.md
$ git add submissions/lab2.md
$ git commit -S -s -m "wip(lab2): start"
[feature/lab2 82133e5] wip(lab2): start
 1 file changed, 1 insertion(+)
 create mode 100644 submissions/lab2.md
$ echo "more important work" >> submissions/lab2.md
$ git commit -S -s -am "wip(lab2): more progress"
[feature/lab2 be1e4df] wip(lab2): more progress
 1 file changed, 1 insertion(+)
 
$ git reset --hard HEAD~2
HEAD is now at 2184bc3 docs(lab1): complete task3

$ git status 
On branch feature/lab2
nothing to commit, working tree clean


$ git log --oneline
2184bc3 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) docs(lab1): complete task3
36b4d4e docs(lab1): finish submission
4ad32ef docs(lab1): finishing task1
428851b docs(lab1): start submission
...


$ git reflog # commits are still here
2184bc3 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{0}: reset: moving to HEAD~2
be1e4df HEAD@{1}: commit: wip(lab2): more progress
82133e5 HEAD@{2}: commit: wip(lab2): start
2184bc3 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{3}: checkout: moving from feature/lab1 to feature/lab2
2184bc3 (HEAD -> feature/lab2, origin/feature/lab1, feature/lab1) HEAD@{4}: commit: docs(lab1): complete task3


$ git reset --hard be1e4df # recovery
HEAD is now at be1e4df wip(lab2): more progress


$ git status
On branch feature/lab2
nothing to commit, working tree clean


$ git log --oneline # the commits are back now.
be1e4df (HEAD -> feature/lab2) wip(lab2): more progress
82133e5 wip(lab2): start
2184bc3 (origin/feature/lab1, feature/lab1) docs(lab1): complete task3
36b4d4e docs(lab1): finish submission
4ad32ef docs(lab1): finishing task1
428851b docs(lab1): start submission

# Question: What would happen if `git gc` had run between the bad reset and your recovery?

# Answer: `git gc` combines many individual objects into efficient packfiles, and deletes old objects that are no longer needed after a grace period
```

- Question: What would happen if `git gc` had run between the bad reset and your recovery?

- Answer: `git gc` combines many individual objects into efficient packfiles, and deletes old objects that are no longer needed after a grace period.
  If a normal `git gc` ran soon after the bad reset , nothing bad would happen. `git gc` might move objects from loose storage into packfiles, which does mean that the commit is gone. A normal `git gc` probably would not prevent recovery. But if Git pruned the unreachable commit after the reflog entry expired, or if someone forced pruning immediately, the commit could be permanently deleted from the local repository.


## Task 2 — Tag a Release & Rebase a Feature

### 2.1: Annotated, signed release tag

```bash
$ git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
v0.0.1 tag commit
v0.1.0-lab2-sarhan tag commit


$ git tag -v "v0.1.0-lab2-${USER}"
object 0ed22bb7e6560b5a7e63903c355d5c41f36f4eb5
type commit
tag v0.1.0-lab2-sarhan
tagger Ahmad Sarhan <ahmadhasansarhana@gmail.com> 1783965617 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for ahmadhasansarhana@gmail.com with RSA key SHA256:E3jxNqQOmWqV0tyNbDOrEN0PDgkqcYP0I8qC0Lf7GLE
```

### 2.2: Rebase + force-with-lease

```bash
## Before rebase
git log --oneline --graph --decorate --all
* be1e4df (feature/lab2) wip(lab2): more progress
* 82133e5 wip(lab2): start
| * 8de962e (upstream/main, upstream/HEAD) docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
| | *   5c30a49 (origin/main, origin/HEAD) Merge pull request #1 from VectorsMaster/feature/lab1
| | |\  
| |_|/  
|/| |   
* | | 2184bc3 (origin/feature/lab1, feature/lab1) docs(lab1): complete task3
* | | 36b4d4e docs(lab1): finish submission
* | | 4ad32ef docs(lab1): finishing task1
* | | 428851b docs(lab1): start submission
|/ /  
| * 00c23c8 (HEAD -> main) docs: add PR template
|/  


## After rebase
git log --oneline --graph
* c595089 (HEAD -> feature/lab2, origin/feature/lab2) wip(lab2): more progress
* 9ce4378 wip(lab2): start
* 03004f7 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* c931ac4 docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
*   5c30a49 Merge pull request #1 from VectorsMaster/feature/lab1
|\  
| * 2184bc3 (origin/feature/lab1, feature/lab1) docs(lab1): complete task3
| * 36b4d4e docs(lab1): finish submission
| * 4ad32ef docs(lab1): finishing task1
| * 428851b docs(lab1): start submission
* | 00c23c8 (backup-main) docs: add PR template
|/  
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
* 356419b docs(lab1,lab2): clarify GitHub auth vs signing SSH key roles; add publickey-denied pitfalls
...
```


### 2.3: Merge-versus-rebase reflection

- I would use **merge** when I want to preserve the exact historical branching structure, especially on shared or public branches.
- I would use **rebase** to clean up private feature-branch history and place my commits on top of the latest base branch.
- I would avoid rebasing commits that other people may already depend on, because rebasing changes commit hashes.
- After rebasing a published personal feature branch, I would use `--force-with-lease`, not `--force`.