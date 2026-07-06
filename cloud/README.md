---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---

# QuickNotes on Hugging Face Spaces

This Space runs the QuickNotes container image published to
`ghcr.io/rikire/devops-intro/quicknotes` by the release CI (Lab 10, Task 1).

The `app_port: 8080` line in the YAML frontmatter above is required: Hugging Face
defaults to port **7860**, but QuickNotes listens on **8080**, so we tell HF to
route the public URL to 8080.

## Endpoints

- `GET /health` → `{"status":"ok","notes":N}`
- `GET /notes`  → list notes
- `POST /notes` → create a note
- `GET /metrics` → Prometheus metrics

> This `README.md` and the sibling `Dockerfile` are the two files pushed to the
> Space's own Git repo. They are kept here under `cloud/` for the course
> submission.
