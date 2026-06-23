## Goal
Complete Lab 5 by adding a reproducible Vagrant setup for QuickNotes and documenting Task 1, Task 2, and the bonus VM-vs-container benchmark.

## Changes
- Task 1: Added a root `Vagrantfile` for Ubuntu 24.04, VirtualBox resource limits, localhost-only port forwarding, synced `app/`, and pinned Go 1.24.5 provisioning.
- Task 2: Documented the snapshot save, break, restore, and recovery workflow in `submissions/lab5.md`.
- Bonus: Added the VM vs Docker resource baseline, comparison table, and measured results in `submissions/lab5.md`.

## Testing
- Task 1: Validated the Vagrant setup, tested the Go app, and checked QuickNotes from both the VM and the host.
- Task 2: Saved a snapshot, deliberately broke the Go install, restored the VM, and verified recovery.
- Bonus: Measured VM boot time, RAM, process count, and disk usage, then compared them with the same metrics for a Docker container.

## Checklist
- [ ] Title is a clear sentence (≤ 70 chars)
- [x] Commits are signed (`git log --show-signature`)
- [x] `submissions/lab5.md` updated
