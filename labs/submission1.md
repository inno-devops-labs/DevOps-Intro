# Lab 1 submission

## Task 1

### A short summary explaining the benefits of signing commits. 

Signing commits allows to verify that commit was made my authorized and trusted user. That helps to insure that account was not stolen (if keys were not also stolen) and code was pushed by known user.

### Evidence of successful SSH key setup and signed commit.

Output of `ssh -T git@github.com`: 

`Hi I-y6o-I! You've successfully authenticated, but GitHub does not provide shell access.`. 

Signed commit
```
commit 764f2a69899591c872fa0f98e41c433fe6dc9d97 (HEAD -> feature/lab1)
Good "git" signature for ki.shumskii@innopolis.university with ED25519 key SHA256:d9zdJAAoG7/t7CN8yhMNIE8nvJXbzzU7YvkBYaeB1YU
Author: |-y6o-| <mailkirill17@gmail.com>
Date:   Fri Feb 6 15:58:25 2026 +0300

    docs: add commit signing summary
```

### Why is commit signing important in DevOps workflows?

As mentioned before signed commits allow to prevent unauthorized or malicious code from entering the pipeline. In devops pipelines that ensures the authenticity of code changes as they move through automated pipelines.

