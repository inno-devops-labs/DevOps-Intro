# Rolan Muliukin Lab 1 submission

## Task 1

- I create my SHH key for this Mac

```bash
ssh-keygen -t ed25519 -C "rolanmuliukin@innopolis.university"
```

![](attachments/pic1-1-1.png)

- And put this key into my git `user.signingkey`

![](attachments/pic1-1-2.png)

- After I create this file, and make the commit. Also I add `ssh.pub` on git  and get `Verified`

![](attachments/pic1-1-3.png)

### Commit signing adds a cryptographic signature to a commit, which proves two things:
1.	Authenticity: the commit was created by the holder of the private SSH key (it’s much harder to impersonate an author).
2.	Integrity: if the commit content changes after signing, the signature becomes invalid, so tampering is detectable.

## Task 2

