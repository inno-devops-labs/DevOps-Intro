#important work
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