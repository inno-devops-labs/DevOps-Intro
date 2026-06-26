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

Lab 10 — serves the same `quicknotes` image published to GHCR.

- Image: `ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0`
- Health: `GET /health`
- Notes API: `GET /notes`, `POST /notes`, etc.

## Why pull from GHCR?

Reuses the exact artifact built and pushed by the release workflow (same digest as `docker pull`). Building from `app/` inside the Space would work but duplicates CI and can drift from the tagged release.
