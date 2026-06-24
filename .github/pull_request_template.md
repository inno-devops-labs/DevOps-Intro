## Goal
Complete Lab 6 for QuickNotes: containerize the app, run it with Compose and persistence, and apply the bonus hardening defaults.

## Changes
- Task 1:
	Add a multi-stage distroless Dockerfile with a static stripped Go binary, nonroot runtime, and image size under 25 MB.
- Task 2:
	Add `compose.yaml` with port publishing, named volume persistence, env vars, restart policy, and a distroless-compatible healthcheck.
- Bonus:
	Harden the `quicknotes` service with `cap_drop: [ALL]`, `read_only: true`, `tmpfs: /tmp`, and `no-new-privileges`; document Docker and Trivy verification in `submissions/lab6.md`.

## Testing
- `go test ./...`
- `docker build -t quicknotes:lab6 ./app`
- `docker run --rm -p 8080:8080 -v "$PWD/app/data:/data" quicknotes:lab6` and `curl /health`
- `docker compose up --build -d`, POST note, verify persistence across `down/up`, verify reset with `down -v`
- `docker inspect` checks for nonroot, dropped capabilities, read-only root, and `no-new-privileges`
- `docker compose exec quicknotes sh` fails as expected
- `trivy image --severity HIGH,CRITICAL quicknotes:lab6`

## Checklist
- [x] Title is a clear sentence (≤ 70 chars)
- [x] Commits are signed (`git log --show-signature`)
- [x] `submissions/labN.md` updated
