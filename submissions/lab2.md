# Lab 2 — Version Control Deep Dive 

## Task 1.1 — Git Object Model Exploration 
$ git rev-parse HEAD 
cbb252da3df8707bd6b3fba6a41556cc31871282 

$ git cat-file -t HEAD 
commit 

$ git cat-file -p HEAD 
tree b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322 
parent 075cb36d6929f5b50e003072df801d93c1455d03 
author ksu ksenya.myasoedova@gmail.com 1780568645 +0300 
committer ksu ksenya.myasoedova@gmail.com 1780568645 +0300 

test: unsigned commit (should fail) 

$ git cat-file -t b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322 
tree 

$ git cat-file -p b2fe0c7c5e1b86c2995fdccb8e8b18e8a19fd322   
040000 tree 1d07791eee3c3dd0955a02402b05b3a357816d8d .github    
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee .gitignore 
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e README.md 
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a app 
040000 tree 6db686e340ecdd318fa43375e26254293371942a labs     
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5 lectures 

$ git cat-file -t 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee 
blob 

$ git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee 
.gitignore content (excluded for brevity) 

## Task 1.2 — .git directory exploration 
$ ls -la .git/ 
total 60 
drwxr-xr-x 7 ksu ksu 4096 Jun 5 15:22 .  
drwxr-xr-x 7 ksu ksu 4096 Jun 5 15:22 .. 
-rw-r--r-- 1 ksu ksu 21 Jun 5 15:22 HEAD 
-rw-r--r-- 1 ksu ksu 456 Jun 4 12:32 config    
drwxr-xr-x 40 ksu ksu 4096 Jun 5 15:22 objects 
drwxr-xr-x 5 ksu ksu 4096 Jun 4 12:05 refs 

$ cat .git/HEAD  
ref: refs/heads/main 

$ ls .git/refs/heads/ 
feature main 



$ find .git/objects -type f | wc -l 
42 

$ ls .git/objects/ | head 
07 
0a 
0e 
1a 
1d 
27 
2a 
38 
47 
48 


### Interpretation 

`.git/HEAD` points to `refs/heads/main` indicating current branch is main. The objects directory contains 42 loose objects stored in 2-character SHA prefix subdirectori> 


more important work


## Task 1.3 — Disaster and Recovery

### Breaking with --hard reset
$ git reset --hard HEAD~2
HEAD is now at 66bbd4d docs(lab1): align Task 3

$ git status
On branch feature/lab2
nothing to commit, working tree clean

### Recovery via reflog
$ git reflog
3063f90 HEAD@{2}: commit: wip(lab2): more progress
0062b37 HEAD@{3}: commit: wip(lab2): start

$ git reset --hard 3063f90
HEAD is now at 3063f90 wip(lab2): more progress

$ git log --oneline
3063f90 wip(lab2): more progress
0062b37 wip(lab2): start

### GC Window Risk Explanation

If `git gc` had run between the bad reset and recovery, the commits would have been garbage collected. By default, reflog entries expire after 90 days, but CI environments with aggressive GC can lose unreachable commits before manual recovery.

