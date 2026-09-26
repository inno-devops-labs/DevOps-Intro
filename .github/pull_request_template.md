## Goal
Implement a PR-gated CI pipeline for QuickNotes with vet, test, and lint checks.

## Changes
- Added GitHub Actions workflow (`.github/workflows/ci.yml`) with three independent jobs: vet, test, lint
- Implemented build matrix for Go 1.23 and 1.24 on vet and test jobs
- Enabled Go module and build caching via `actions/setup-go`
- Added path filtering to skip CI on docs-only changes
- SHA-pinned all third-party actions with full 40-character commits
- Set least privilege permissions (`contents: read`)
- Added aggregation job (`ci-ok`) for branch protection compatibility
- Created comprehensive submission documentation in `submissions/lab3.md`
- Tested CI gate with deliberate failure (commit 6da4384) and fix (commit af83241)

## Testing
- CI pipeline runs on push to main and PRs targeting main
- All three jobs (vet, test, lint) execute correctly against the `app/` directory
- Matrix successfully tests both Go 1.23 and 1.24 in parallel
- Branch protection configured to require `ci-ok` status check before merging
- Deliberate test failure (commit 6da4384) correctly fails the pipeline
- Fix commit (af83241) successfully passes all CI checks

## Checklist
- [x] Title is a clear sentence (≤ 70 chars)
- [x] Commits are signed (`git log --show-signature`)
- [x] `submissions/lab3.md` updated