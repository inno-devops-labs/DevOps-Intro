# Lab 1 Submission — Introduction to DevOps & Git Workflow

**Student:** Diana Minnakhmetova
**Date:** 31-01-2026

---

## Task 1

### 1.1 Why signed commits matter

Commit signing is basically a way to prove that you actually wrote the code you're claiming to write. It uses cryptography to verify both the author's identity and that nobody messed with the commit after it was created.

In DevOps this is pretty important because:

1) Anyone with repo access could technically commit as "you" if they wanted to. Signing prevents impersonation because you need the private key to create a valid signature.

2) The signature breaks if even one character in the commit changes after signing. So you can tell if someone tampered with the history.

3) A lot of security standards require this kind of verification trail, especially in regulated industries.

SSH signing is simpler than GPG because you can reuse the same keys you already use for authentication, and you don't have to deal with keyservers or expiration dates.
