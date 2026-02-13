# Lab 2 — Version Control & Advanced Git

**Student:** Kamilya Shakirova
**Date:** 12-02-2026

---

## Task 1 — Git Object Model Exploration

- [x] All command outputs for object inspection.
- [] A 1–2 sentence explanation of what each object type represents.
- [] Analysis of how Git stores repository data.
- [x] Example of blob, tree, and commit object content.

### 1.1: Sample Commits Created
``` sh
PS D:\Programs\DevOps-Intro> echo "Test content" > test.txt
PS D:\Programs\DevOps-Intro> git add test.txt
PS D:\Programs\DevOps-Intro> git commit -m "Add test file"
[feature/lab2 5ec7cf4] Add test file
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 test.txt
```
### 1.2: Inspection of Git Objects
Finding objects' hashes. \
**Get commit hash**
``` sh
PS D:\Programs\DevOps-Intro> git log --oneline -1
5ec7cf4 (HEAD -> feature/lab2) Add test file
```
**Get tree hash from commit**
``` sh
PS D:\Programs\DevOps-Intro> git cat-file -p HEAD
tree 41d94804accf3a3ecf75e1727453aa732970fcba
parent 54bd17fad12ef27baa683be885a511009e142678
author Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
committer Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgTq8Y3An3dqp1qK8NzZqtGd2rlP
 NCv//QZIL2P7QI0JoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKlGcRLbkEbWXxPV9hennSs5ukgP5H+fYQsy8zNBCq+cFsA4jgZjRXwHbFcnmL7tSJ
 6HNYvLaMMCBwRzJ5zkmgg=
 -----END SSH SIGNATURE-----

Add test file
```

**Get blob hash from tree**
``` sh
PS D:\Programs\DevOps-Intro> git cat-file -p 41d94804accf3a3ecf75e1727453aa732970fcba
040000 tree 4c530fb14ed774958906540e7f66da8babf2f1fd    .github
100644 blob 6e60bebec0724892a7c82c52183d0a7b467cb6bb    README.md
040000 tree a1061247fd38ef2a568735939f86af7b1000f83c    app
040000 tree eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0    labs
040000 tree d3fb3722b7a867a83efde73c57c49b5ab3e62c63    lectures
100644 blob 418a98ced2ac70b5bdee0be9732ecdaae7264515    test.txt
```

``` sh
# Blob content
PS D:\Programs\DevOps-Intro> git cat-file -p 418a98ced2ac70b5bdee0be9732ecdaae7264515
��Test content

# Tree content
PS D:\Programs\DevOps-Intro> git cat-file -p eb79e5a468ab89b024bd4f3ed867c6a3954fe1f0
100644 blob aa6b7b5c478b439d2c1e9b4f085257782dd68d25    lab1.md
100644 blob cf1ba99be683932b0a1e1cfd84f0d6f0dc0d184f    lab10.md
100644 blob ca6bbf33cb79a950fbf3c517e6b174ac65f5334b    lab11.md
040000 tree 16bf9eb348f7da4acbec0a94fc4a09e46c40064f    lab11
100644 blob fcd2509fd7a30ea3b5cc9e879f97fbb32d3e660d    lab12.md
040000 tree 129069dd8e40511c9ab6c889b375532b1d68fde3    lab12
100644 blob 3128f48b832e6592d02ae82a18f9b89af82c9658    lab2.md
100644 blob 6e453f5c97f02a4bca77db29549154072771ad4a    lab3.md
100644 blob 3aa4439565d04ff637e909ffc164d59a60749239    lab4.md
100644 blob 0435c3fcbd5d21b21cf253af0544a6536247cdb9    lab5.md
100644 blob af90a7fa02f582cd3d31f4d9f71360878f031e92    lab6.md
100644 blob ee11bdfb0d71048268ec439ad0c4ee2f7bf6fd1b    lab7.md
100644 blob 9df09119213b81f88f6b61c89f3bcf223a32ecf6    lab8.md
100644 blob 12e1b875e40d5ef91f11c36fb259f23069fc458f    lab9.md

# Commit content
PS D:\Programs\DevOps-Intro> git cat-file -p 5ec7cf4                                 
tree 41d94804accf3a3ecf75e1727453aa732970fcba
parent 54bd17fad12ef27baa683be885a511009e142678
author Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
committer Kamilya Shakirova <94891282+Kamilya05@users.noreply.github.com> 1770904418 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgTq8Y3An3dqp1qK8NzZqtGd2rlP
 NCv//QZIL2P7QI0JoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQKlGcRLbkEbWXxPV9hennSs5ukgP5H+fYQsy8zNBCq+cFsA4jgZjRXwHbFcnmL7tSJ
 6HNYvLaMMCBwRzJ5zkmgg=
 -----END SSH SIGNATURE-----

Add test file
```
