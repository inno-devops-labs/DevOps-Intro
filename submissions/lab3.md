# Lab 3 Submission

**Path:** GitHub Actions

## Task 1 — PR Gate

### Design Questions

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?**

`ubuntu-latest` can change over time, breaking builds. Pinning ensures reproducibility.

**b) Why split vet + test + lint into separate units?**

Parallel execution is faster, failures are easier to debug, and you can retry only failed jobs.

**c) What real attack does SHA pinning prevent? (Cite date + incident name)**

`tj-actions/changed-files` incident (March 2025). SHA pinning prevents tag compromise.

**d) What is `permissions:` and the principle behind it?**

`permissions:` sets access rights. Least privilege principle — give only what's needed (`contents: read`).

### Evidence

- **Green CI:** ![green](image.png)
- **Red CI:** ![red](image-1.png)
- **Branch protection:** ![branch](image-2.png)

---

## Task 2 — Make It Fast and Smart

### Timing Table

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go version) | ~40 s |
| With cache | ~40 s |
| With cache + matrix | ~45 s |

> QuickNotes has zero external dependencies, so cache has minimal effect.

### Design Questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

`go.sum` uniquely defines dependencies, ensuring a reproducible cache key.

**g) What does `fail-fast: false` change?**

Without it, one failure cancels all other matrix jobs. With `fail-fast: false`, all jobs run to completion.

**h) What's the risk of an attacker writing a cache from a malicious PR?**

GitHub isolates caches from forks — they are not restored to protected branches.

### Evidence

- **Cache:** ![cache](image-3.png)
- **Matrix:** ![matrix](image.png)
- **Path filter:** Configured with `paths: 'app/**'`. CI only runs on `app/` or CI config changes. Due to an already open PR, GitHub ran the workflow anyway. The paths configuration is still correct and would work for new branches.

---

## Bonus Task (if attempted)

*Not attempted.*