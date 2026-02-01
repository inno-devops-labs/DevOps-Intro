# Lab 1 Submission — Introduction to DevOps & Git Workflow

**Student:** Diana Minnakhmetova
**Date:** 01-02-2026

---

## Task 1

[X] A short summary explaining the benefits of signing commits.

[X] Evidence of successful SSH key setup and signed commit.

[X] Answer: "Why is commit signing important in DevOps workflows?"

[X] Screenshots or verification of the "Verified" badge on GitHub.



#### Preresquites

```
dminnakhmetova@MacBook-Air-Diana-3 S25 % git clone https://github.com/mnkhmtv/DevOps-Intro.git
Клонирование в «DevOps-Intro»...
remote: Enumerating objects: 98, done.
remote: Counting objects: 100% (32/32), done.
remote: Compressing objects: 100% (22/22), done.
remote: Total 98 (delta 17), reused 10 (delta 10), pack-reused 66 (from 2)
Получение объектов: 100% (98/98), 309.47 КиБ | 1.14 МиБ/с, готово.
Определение изменений: 100% (38/38), готово.
dminnakhmetova@MacBook-Air-Diana-3 S25 % cd DevOps-Intro 
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git switch -c feature/lab1
Переключились на новую ветку «feature/lab1»
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % touch labs/submission1.md
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add labs/submission1.md
```

### 1.1 Explore the Importance of Signed Commits

Signing commits proves that you actually wrote the code and nobody changed it after. It uses your SSH key like a digital signature, so even if someone hacks your GitHub account, they can't pretend to be you without stealing your laptop. Basically it's protection against both impersonation and tampering with commit history.

**Why is commit signing important in DevOps workflows?**

– In DevOps, code gets deployed automatically through CI/CD pipelines, so if someone compromises a developer's account and pushes malicious code, signing is the only way to prove it wasn't actually them. It's basically an audit trail that shows exactly who wrote what, which matters both for security investigations and for compliance requirements in regulated industries.



### 1.2 Set Up SSH Commit Signing


```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % ssh-keygen -t ed25519 -C "mnkhmtvv@gmail.com"    
Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/dminnakhmetova/.ssh/id_ed25519): 
/Users/dminnakhmetova/.ssh/id_ed25519 already exists.
Overwrite (y/n)? y
Enter passphrase for "/Users/dminnakhmetova/.ssh/id_ed25519" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/dminnakhmetova/.ssh/id_ed25519
Your public key has been saved in /Users/dminnakhmetova/.ssh/id_ed25519.pub
The key fingerprint is:
SECRET mnkhmtvv@gmail.com
The key's randomart image is:
+--[ED25519 256]--+
SECRET
+----[SHA256]-----+
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % cat ~/.ssh/id_ed25519.pub
SECRET mnkhmtvv@gmail.com
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git config --global user.signingkey ~/.ssh/id_ed25519.pub
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git config --global commit.gpgSign true
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git config --global gpg.format ssh
```

**Result: GitHub SSH key**  
![SSH key](https://github.com/user-attachments/assets/641ff699-7256-4103-b734-f4911f1b0f37)

### 1.3 Make a Signed Commit

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add labs/submission1.md                              
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git commit -S -m "docs: add commit signing summary"
[feature/lab1 206c1df] docs: add commit signing summary
 1 file changed, 2 insertions(+)
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git push -u origin feature/lab1
```

**Result: GitHub Verification Badge**  
![Verified commit on GitHub](https://github.com/user-attachments/assets/0493da3e-aef7-4113-9b9e-74c68e3b3b01)

## Task 2
[X] Screenshot of PR template auto-filling the description.

[X] Evidence that .github/pull_request_template.md exists on main branch.

[X] Analysis of how PR templates improve collaboration.

[X] Note any challenges encountered during setup.

#### How PR templates improve collaboration

PR templates solve a pretty fundamental problem in team development which is an inconsistent communication. Without a template, every developer writes PR descriptions differently and then reviewers end up wasting time asking the same questions over and over: "What does this change?" "Did you test it?" "Why are we doing this?"

Templates fix this by creating a shared structure. When everyone fills out the same sections, reviewers can quickly scan for what they need without hunting through random text or pinging the author for context. This is especially valuable in async workflows where people are in different timezones—you can't just tap someone on the shoulder to ask "what's this PR about?"

The checklist part is surprisingly effective too. Simple things like "did you update the docs?" or "did you accidentally commit secrets?" catch issues before they hit review. It's basically a pre-flight check that prevents stupid mistakes from wasting everyone's time.

For new contributors, templates are like scaffolding. Instead of looking at past PRs and trying to reverse-engineer what's expected, they see the structure immediately. This lowers the barrier to entry and makes onboarding smoother.


### 2.1 Create PR Template

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git checkout main
Переключились на ветку «main»
Эта ветка соответствует «origin/main».
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % mkdir -p .github
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % nano .github/pull_request_template.md
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add .github/pull_request_template.md
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git commit -S -m "feat: add PR template"
[main 97fa04a] feat: add PR template
 1 file changed, 23 insertions(+)
 create mode 100644 .github/pull_request_template.md
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git push origin main
```

**PR template:**

```
##  Goal

<!-- What does this PR accomplish? -->

## Changes

<!-- List the main changes made -->

- 

## Testing

<!-- How was it verified? -->

---

## Checklist

- [ ] Clear, descriptive PR title

- [ ] Documentation/README updated (if needed)

- [ ] No secrets or large temporary files committed
```

PR template – [Link](https://github.com/mnkhmtv/DevOps-Intro/blob/main/.github/pull_request_template.md)

### 2.2 Create Lab Branch and Open PR

```
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git checkout feature/lab1
Переключились на ветку «feature/lab1»
Эта ветка соответствует «origin/feature/lab1».
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git add .                                     
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git commit -m "docs: add lab1 submission stub"
[feature/lab1 43d9753] docs: add lab1 submission stub
 1 file changed, 22 insertions(+), 2 deletions(-)
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % git push -u origin feature/lab1
Перечисление объектов: 7, готово.
Подсчет объектов: 100% (7/7), готово.
При сжатии изменений используется до 8 потоков
Сжатие объектов: 100% (4/4), готово.
Запись объектов: 100% (4/4), 1.21 КиБ | 1.21 МиБ/с, готово.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To https://github.com/mnkhmtv/DevOps-Intro.git
   206c1df..43d9753  feature/lab1 -> feature/lab1
branch 'feature/lab1' set up to track 'origin/feature/lab1'.
```

**Result: PR template autofilled**  
![Autofilling](https://github.com/user-attachments/assets/cb638a46-19ec-4aa7-93e2-3c2f50da8bb4)
