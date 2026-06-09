# Lab 1 submission

### Output of `curl` against `/health`, `/notes`, and `POST /notes`

![[Pasted image 20260609172958.png]]
![[Pasted image 20260609173020.png]]
![[Pasted image 20260609191240.png]]

### Output of `git log --show-signature -1` showing **Good** signature

Nedeed to run command below for task to be done: 
`echo "elfsgithub@gmail.com $(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers`

![[Pasted image 20260609192828.png]]

### A screenshot of the Verified badge on your platform's PR/commit page

![[Pasted image 20260609193127.png]]

### A 2-3 sentence explanation: _why_ signed commits matter (referencing the xz-utils March 2024 story from Lecture 1)

Story from lecture - in **March 2024**, an attacker (account `JiaT75`) maintained the **xz-utils** project for two years and slipped in a backdoor that nearly compromised every SSH daemon on Linux. Because there was no sighning for commits it could be anyone who could commit compromised changes and there is no way of proving otherwise. Signed commits are proven to be from at least developer's device that holds this key, so that adds at least one security layer, which is good

Nocised that folder was copied into system folder, changed lokation of it.

### Task 2

### Task 3 - GitHub Community Engagement

Stars: 
![[Pasted image 20260609214203.png]]

follows:
![[Pasted image 20260609214253.png]]

- Why starring repositories matters in open source:

Starring a repository is a way to show appreciation to maintainers and bookmark projects I find useful. Stars help open-source projects gain visibility and credibility, which attracts more contributors and users.

- How following developers helps in team projects and professional growth:

Following developers and teammates creates a feed of their activity on GitHub. This helps me stay updated on what my peers are working on, learn from their contributions, and collaborate more effectively in team projects, for them this is sign of my interest in their work.

### Bonus Task

