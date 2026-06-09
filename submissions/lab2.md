#important work

#test commit Verified

```git rev-parse HEAD```

66bbd4db9228bc9a4cab7439746b993749c026ab

```git cat-file -t HEAD```

commit

```git cat-file -p HEAD```

tree 20bda2b2625085720751a3e794f82e5625a409b3
parent 170000c9d1b5e90a37b6f1a9b826552d53051773
author Dmitrii Creed <creeed22@gmail.com> 1780392934 +0400
committer Dmitrii Creed <creeed22@gmail.com> 1780394046 +0400

```git cat-file -p 20bda2b2625085720751a3e794f82e5625a409b3```

100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee    .gitignore
100644 blob d10c04c6e7e0014f4fe883599c11747c15012d4e    README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a    app
040000 tree 6db686e340ecdd318fa43375e26254293371942a    labs
040000 tree 3f11973a71be5915539cb53313149aa319d69cb5    lectures

```git cat-file -p 7d0898a908e274ea809722844cdbd836f3b1c05a```

100644 blob 8ba1a5234925005265281bf7809153487097373c    .golangci.yml
100644 blob 24ab0258318f4aac6ec7d3a924a1d6f05209b446    Makefile
100644 blob 1aed7f8904100182d3fb4e1b90dbf3bd5a126beb    README.md
100644 blob b76e91cf916dcebc1d6898e22012c737c117003a    go.mod
100644 blob c534979c5a3aa0e032fb61e1562d4bd343ecaf4c    handlers.go
100644 blob 9dff2e3e5b734f9afa4bc26c30d784bee8aa327c    handlers_test.go
100644 blob e258ffcfe44ebc6923eb78d51c63fc2317aa1dfd    main.go
100644 blob ecf4fd2edd38dcbc82459122660aa424342f9148    seed.json
100644 blob 4a9ca2b3a371cc43f8762095a6944cd96ea7d7d0    store.go
100644 blob 3b8ff9d45ae9e6781ffe333ccc7eff40da35a1bf    store_test.go

```ls -la .git/```

total 25
drwxr-xr-x 1 UserName 197121    0 Jun  9 15:17 ./
drwxr-xr-x 1 UserName 197121    0 Jun  9 15:18 ../
-rw-r--r-- 1 UserName 197121   80 Jun  8 00:20 COMMIT_EDITMSG
-rw-r--r-- 1 UserName 197121  189 Jun  8 00:34 config
-rw-r--r-- 1 UserName 197121   73 Jun  4 00:25 description
-rw-r--r-- 1 UserName 197121    0 Jun  9 15:22 FETCH_HEAD
-rw-r--r-- 1 UserName 197121   29 Jun  9 15:17 HEAD
drwxr-xr-x 1 UserName 197121    0 Jun  4 00:25 hooks/
-rw-r--r-- 1 UserName 197121 3055 Jun  9 15:16 index
drwxr-xr-x 1 UserName 197121    0 Jun  4 00:25 info/
drwxr-xr-x 1 UserName 197121    0 Jun  4 00:25 logs/
drwxr-xr-x 1 UserName 197121    0 Jun  9 15:22 objects/
-rw-r--r-- 1 UserName 197121   46 Jun  4 00:32 packed-refs
drwxr-xr-x 1 UserName 197121    0 Jun  4 00:25 refs/

```cat .git/HEAD```

ref: refs/heads/feature/lab2

```ls .git/refs/heads/```

feature/  main

```ls .git/objects/ | head```

0a/
0c/
0e/
0f/
13/
1a/
27/
38/
3a/
40/

```find .git/objects -type f | wc -l```

29


```git log --oneline```

66bbd4d (HEAD -> feature/lab2, main) docs(lab1): align Task 3 GitHub Community engagement with other courses
170000c Merge pull request #907 from inno-devops-labs/s26-refactor
d50436c fix(lab12,gitignore): Spin SDK (WAGI removed in Spin 3.x); minimal student-safe gitignore
4705a3d fix(.gitignore): stop ignoring submissions/
4082340 docs(grading,lab11,lab12): bonus labs to 4+4+2; grading rebalanced to 70-14-5-20-30 = 139%
7b16dc5 docs(lab10): switch deploy targets to card-free platforms — HF Spaces + Cloudflare Tunnel
4a05efa docs(labs): scaffold the skill — labs 5-12 stop handing students copy-paste answers
8387fb9 docs(lab3): scaffold the skill — students write their own CI yaml; GitLab as parallel path
983fba0 docs(course): rewrite README + add .gitignore for project-threaded structure
7914e37 docs(labs): refactor 12 labs to 6+4+2 (lab1) / 6+4+bonus (lab2-10) / 10pts (lab11-12)
aa5aa1c docs(lectures): rewrite lec1-10 + add reading11/12 for project-threaded course
b8fc480 feat(app): introduce QuickNotes Go service for project-threaded course
6f044dd Replace IPFS with Nix
0a87e1c refactor: reduce prescriptiveness in GitLab CI instructions
eaea715 feat: add GitLab CI alternative instructions to lab3
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

```git reflog```

66bbd4d (HEAD -> feature/lab2, main) HEAD@{0}: reset: moving to HEAD~2
03cdb25 HEAD@{1}: commit: lab1
9a2873e HEAD@{2}: commit: wip(lab2): Work progress
66bbd4d (HEAD -> feature/lab2, main) HEAD@{3}: checkout: moving from main to feature/lab2
66bbd4d (HEAD -> feature/lab2, main) HEAD@{4}: checkout: moving from feature/lab1 to main
dce058f (feature/lab1) HEAD@{5}: checkout: moving from main to feature/lab1
66bbd4d (HEAD -> feature/lab2, main) HEAD@{6}: checkout: moving from feature/lab1 to main
dce058f (feature/lab1) HEAD@{7}: commit: docs(lab1): start submission
66bbd4d (HEAD -> feature/lab2, main) HEAD@{8}: checkout: moving from main to feature/lab1
66bbd4d (HEAD -> feature/lab2, main) HEAD@{9}: clone: from https://github.com/sovva6-14/DevOps-Intro.git

```git reset --hard 9a2873e```

HEAD is now at 9a2873e wip(lab2): Work progress

```git push origin "v0.1.0-lab2-Sovva"```


Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 420 bytes | 420.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/sovva6-14/DevOps-Intro.git
 * [new tag]         v0.1.0-lab2-Sovva -> v0.1.0-lab2-Sovva

 ```git commit -S -s --allow-empty -m "docs: upstream moved while you worked"```

[feature/lab2 04b5e86] docs: upstream moved while you worked


```git push --force-with-lease origin feature/lab2```

Enumerating objects: 14, done.
Counting objects: 100% (14/14), done.
Delta compression using up to 20 threads
Compressing objects: 100% (10/10), done.
Writing objects: 100% (13/13), 3.95 KiB | 3.96 MiB/s, done.
Total 13 (delta 7), reused 6 (delta 1), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (7/7), completed with 1 local object.
To https://github.com/sovva6-14/DevOps-Intro.git
 + be131f7...04b5e86 feature/lab2 -> feature/lab2 (forced update)