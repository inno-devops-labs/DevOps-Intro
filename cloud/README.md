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

A tiny Go notes API, deployed as a Docker Space. The container image is pulled
from GitHub Container Registry (built by the Lab 10 release workflow).

`app_port: 8080` is required because QuickNotes listens on **8080**, not Hugging
Face's default **7860**.

## Endpoints

- `GET /health` → `{"status":"ok","notes":N}`
- `GET /notes` → list notes
- `POST /notes` → create a note (`{"title":"...","body":"..."}`)

## Deploy

This directory (`cloud/`) mirrors the files that live in the **Space repo**:
`Dockerfile` (pulls `ghcr.io/<you>/devops-intro/quicknotes:v0.1.0`) and this
`README.md` with the Space metadata frontmatter. Push them to the Space's git
remote and Hugging Face auto-builds and serves at
`https://<user>-<spacename>.hf.space`.
